import XCTest
@testable import Logbook

@MainActor
final class LogbookStoreTests: XCTestCase {
    func testBundledExerciseAndFoodCatalogsLoadForAnEmptyRepository() {
        let store = LogbookStore(repository: temporaryRepository())
        XCTAssertTrue(store.state.training.exercises.contains { $0.id == "builtin-2" && $0.name == "Flat barbell bench press" })
        XCTAssertFalse(store.state.nutrition.foods.isEmpty)
    }

    func testFoodAdditionRequiresQuantityConfirmationAndPersistsSnapshot() throws {
        let repository = temporaryRepository()
        let store = LogbookStore(repository: repository)
        let meal = try XCTUnwrap(store.state.nutrition.meals.first)
        let food = FoodDefinition(id: "test-oats", name: "Oats", basisAmount: 100, basisUnit: "g", calories: 380, protein: 13, carbohydrates: 68, fat: 7)

        store.addFoodDefinition(food)
        XCTAssertFalse(store.logFood(food, meal: meal, quantity: 50, unit: "g", confirmed: false))
        XCTAssertTrue(store.state.nutrition.logs.isEmpty)
        XCTAssertTrue(store.logFood(food, meal: meal, quantity: 50, unit: "g", confirmed: true))
        XCTAssertEqual(store.state.nutritionTotals(on: LocalDay.string()).calories ?? 0, 190, accuracy: 0.001)
        XCTAssertEqual(store.state.nutritionTotals(on: LocalDay.string()).protein ?? 0, 6.5, accuracy: 0.001)

        let reopened = LogbookStore(repository: repository)
        let log = try XCTUnwrap(reopened.state.nutrition.logs.first)
        XCTAssertEqual(log.foodName, "Oats")
        XCTAssertEqual(log.quantity, 50)
        XCTAssertEqual(log.calories, 190, accuracy: 0.001)
        XCTAssertEqual(log.mealName, meal.name)
    }

    func testVerifiedFoodPortionsHistoricalGoalsAndAdherenceAreConsistent() throws {
        let repository = temporaryRepository()
        let store = LogbookStore(repository: repository)
        let meal = try XCTUnwrap(store.state.nutrition.meals.first)
        let oats = FoodDefinition(id: "cnf-oats-test", name: "Oats", basisAmount: 100, basisUnit: "g",
            calories: 380, protein: 13, carbohydrates: 68, fat: 7, source: "Canadian Nutrient File",
            verifiedServingGrams: 40, sourceURL: "https://food-nutrition.canada.ca/cnf-fce/")

        XCTAssertEqual(oats.multiplier(for: 1, unit: "serving") ?? -1, 0.4, accuracy: 0.0001)
        XCTAssertEqual(oats.multiplier(for: 1, unit: "oz") ?? -1, 0.283495, accuracy: 0.0001)
        XCTAssertNil(oats.multiplier(for: 1, unit: "cup"), "Unverified volume conversions are not offered")
        store.setNutritionTargets(calories: 2_000, protein: 100, carbohydrates: 220, fat: 65, effectiveDate: "2026-11-07")
        store.setNutritionTargets(calories: 2_200, protein: 120, carbohydrates: 240, fat: 70, effectiveDate: "2026-11-08")
        XCTAssertEqual(store.state.nutritionTargets(on: "2026-11-07").calories ?? -1, 2_000)
        XCTAssertEqual(store.state.nutritionTargets(on: "2026-11-08").calories ?? -1, 2_200)
        XCTAssertTrue(store.logFood(oats, meal: meal, quantity: 1, unit: "serving", confirmed: true, date: "2026-11-07"))
        XCTAssertEqual(store.state.nutritionTotals(on: "2026-11-07").calories ?? 0, 152, accuracy: 0.001)
        XCTAssertEqual(store.state.nutritionTotals(on: "2026-11-07").protein ?? 0, 5.2, accuracy: 0.001)
        XCTAssertEqual(store.state.nutritionAdherence(on: "2026-11-08"), .unlogged)
        XCTAssertEqual(store.state.nutritionAdherence(on: "2026-11-07"), .belowGoal)

        let reopened = LogbookStore(repository: repository)
        XCTAssertEqual(reopened.state.nutrition.targetHistory?.count, 3, "The legacy baseline remains alongside the two effective-dated goals")
        XCTAssertEqual(reopened.state.nutrition.foods.first(where: { $0.id == oats.id })?.verifiedServingGrams, 40)
        XCTAssertEqual(reopened.state.nutrition.logs.first?.date, "2026-11-07")
    }

    func testMealCopyReplaceOnlyTouchesMatchingMealsAndKeepsEntrySnapshots() throws {
        let store = LogbookStore(repository: temporaryRepository())
        let foods = [
            FoodDefinition(id: "copy-a", name: "Egg", basisAmount: 1, basisUnit: "piece", calories: 70, protein: 6, carbohydrates: 0, fat: 5),
            FoodDefinition(id: "copy-b", name: "Toast", basisAmount: 1, basisUnit: "slice", calories: 90, protein: 4, carbohydrates: 15, fat: 1)
        ]
        let breakfast = MealSlot(name: "Breakfast")
        let snack = MealSlot(name: "Snack")
        let dinner = MealSlot(name: "Dinner")
        XCTAssertTrue(store.logFood(foods[0], meal: breakfast, quantity: 2, unit: "piece", confirmed: true, date: "2026-11-06"))
        XCTAssertTrue(store.logFood(foods[1], meal: snack, quantity: 1, unit: "slice", confirmed: true, date: "2026-11-06"))
        XCTAssertTrue(store.logFood(foods[1], meal: breakfast, quantity: 1, unit: "slice", confirmed: true, date: "2026-11-07"))
        XCTAssertTrue(store.logFood(foods[0], meal: dinner, quantity: 1, unit: "piece", confirmed: true, date: "2026-11-07"))

        XCTAssertEqual(store.copyMeals(from: "2026-11-06", to: "2026-11-07", replaceMatchingMeals: false), 2)
        XCTAssertEqual(store.state.nutrition.logs.filter { $0.date == "2026-11-07" && $0.deletedAt == nil }.count, 4, "Add appends copied entries without removing existing destination foods")
        XCTAssertEqual(store.copyMeals(from: "2026-11-06", to: "2026-11-07", replaceMatchingMeals: true), 2)
        let copied = store.state.nutrition.logs.filter { $0.date == "2026-11-07" && $0.deletedAt == nil }
        XCTAssertEqual(copied.count, 3, "The matching breakfast is replaced; unrelated dinner remains")
        XCTAssertEqual(copied.filter { $0.mealName == "Breakfast" }.map(\.foodName), ["Egg"])
        XCTAssertTrue(copied.contains { $0.mealName == "Dinner" && $0.foodName == "Egg" })
        XCTAssertEqual(store.recentlyDeletedFoodLogs().filter { $0.date == "2026-11-07" }.count, 3, "Replace preserves every matching destination record removed by Add then Replace")
        XCTAssertEqual(copied.first(where: { $0.foodName == "Egg" && $0.mealName == "Breakfast" })?.calories, 140)
        XCTAssertNotEqual(copied.first(where: { $0.mealName == "Breakfast" })?.id, store.state.nutrition.logs.first(where: { $0.date == "2026-11-06" })?.id)
    }

    func testFoodDeleteRestoreFavoritesRecipeAndWaterPersist() throws {
        let repository = temporaryRepository()
        let store = LogbookStore(repository: repository)
        let meal = try XCTUnwrap(store.state.nutrition.meals.first)
        let banana = FoodDefinition(id: "personal-banana", name: "Banana", basisAmount: 100, basisUnit: "g", calories: 89, protein: 1.1, carbohydrates: 22.8, fat: 0.3, source: "Personal manual entry", isPersonal: true)
        XCTAssertTrue(store.logFood(banana, meal: meal, quantity: 100, unit: "g", confirmed: true, date: "2026-11-08"))
        let log = try XCTUnwrap(store.state.nutrition.logs.first)
        store.setFoodFavorite(banana.id, isFavorite: true)
        let ingredient = try XCTUnwrap(store.makeRecipeIngredient(food: banana, quantity: 100, unit: "g"))
        let recipeID = try XCTUnwrap(store.saveRecipe(name: "Banana bowl", ingredients: [ingredient], yieldAmount: 2, yieldUnit: "servings"))
        let recipe = try XCTUnwrap(store.state.nutrition.recipes?.first(where: { $0.id == recipeID }))
        let recipeFood = store.foodDefinition(for: recipe)
        XCTAssertEqual(recipeFood.calories, 44.5, accuracy: 0.001)
        XCTAssertTrue(store.logFood(recipeFood, meal: meal, quantity: 1, unit: "servings", confirmed: true, date: "2026-11-08"))
        store.addWater(500, date: "2026-11-08")
        store.setWaterGoal(2_000)
        let water = try XCTUnwrap(store.state.nutrition.water.first)
        XCTAssertTrue(store.updateWaterLog(water.id, milliliters: 750, date: "2026-11-07"))
        store.removeWater(water.id)
        XCTAssertEqual(store.recentlyDeletedWaterLogs().map(\.id), [water.id])
        XCTAssertTrue(store.restoreDeletedWaterLog(water.id))
        store.deleteRecipe(recipeID)
        XCTAssertEqual(store.recentlyDeletedRecipes().map(\.id), [recipeID])
        XCTAssertTrue(store.restoreDeletedRecipe(recipeID))
        store.deleteFoodLog(log.id)
        XCTAssertTrue((store.state.nutritionTotals(on: "2026-11-08").calories ?? 0) < 100)
        XCTAssertEqual(store.recentlyDeletedFoodLogs().map(\.id), [log.id])
        XCTAssertTrue(store.restoreDeletedFoodLog(log.id))

        let reopened = LogbookStore(repository: repository)
        XCTAssertTrue(reopened.state.nutrition.favoriteFoodIDs?.contains(banana.id) == true)
        XCTAssertEqual(reopened.state.nutrition.waterGoalMilliliters, 2_000)
        XCTAssertEqual(reopened.state.nutrition.water.first?.milliliters, 750)
        XCTAssertEqual(reopened.state.nutrition.water.first?.date, "2026-11-07")
        XCTAssertEqual(reopened.state.nutrition.recipes?.first?.name, "Banana bowl")
        XCTAssertNil(reopened.state.nutrition.logs.first(where: { $0.id == log.id })?.deletedAt)
    }

    func testEditingRecipeChangesFutureNutritionWithoutRewritingLoggedSnapshot() throws {
        let repository = temporaryRepository()
        let store = LogbookStore(repository: repository)
        let meal = try XCTUnwrap(store.state.nutrition.meals.first)
        let oats = FoodDefinition(id: "recipe-oats", name: "Oats", basisAmount: 100, basisUnit: "g", calories: 380, protein: 13, carbohydrates: 68, fat: 7, isPersonal: true)
        let firstIngredient = try XCTUnwrap(store.makeRecipeIngredient(food: oats, quantity: 100, unit: "g"))
        let recipeID = try XCTUnwrap(store.saveRecipe(name: "Oat bowl", ingredients: [firstIngredient], yieldAmount: 1, yieldUnit: "servings"))
        let initialRecipe = try XCTUnwrap(store.state.nutrition.recipes?.first { $0.id == recipeID })
        XCTAssertTrue(store.logFood(store.foodDefinition(for: initialRecipe), meal: meal, quantity: 1, unit: "servings", confirmed: true, date: "2026-11-07"))
        let historical = try XCTUnwrap(store.state.nutrition.logs.first)

        let revisedIngredient = try XCTUnwrap(store.makeRecipeIngredient(food: oats, quantity: 200, unit: "g"))
        XCTAssertEqual(store.saveRecipe(name: "Oat bowl revised", ingredients: [revisedIngredient], yieldAmount: 1, yieldUnit: "servings", id: recipeID), recipeID)
        let revisedRecipe = try XCTUnwrap(store.state.nutrition.recipes?.first { $0.id == recipeID })
        XCTAssertEqual(store.foodDefinition(for: revisedRecipe).calories, 760, accuracy: 0.001)

        let reopened = LogbookStore(repository: repository)
        let savedLog = try XCTUnwrap(reopened.state.nutrition.logs.first { $0.id == historical.id })
        XCTAssertEqual(savedLog.foodName, "Oat bowl")
        XCTAssertEqual(savedLog.calories, 380, accuracy: 0.001, "Recipe changes affect future food logs; past entries retain nutrient snapshots")
        XCTAssertEqual(savedLog.date, "2026-11-07")
    }

    func testRecentlyDeletedFoodExpiresAndEarlyPermanentDeletePersists() throws {
        let repository = temporaryRepository()
        let store = LogbookStore(repository: repository)
        let meal = try XCTUnwrap(store.state.nutrition.meals.first)
        let food = FoodDefinition(id: "expiry-test-food", name: "Expiry test food", basisAmount: 100, basisUnit: "g", calories: 10, protein: 1, carbohydrates: 1, fat: 0)
        XCTAssertTrue(store.logFood(food, meal: meal, quantity: 100, unit: "g", confirmed: true))
        let expiredLog = try XCTUnwrap(store.state.nutrition.logs.first)
        let expiredAt = Date.now.addingTimeInterval(-31 * 24 * 60 * 60)
        store.deleteFoodLog(expiredLog.id, at: expiredAt)
        store.addWater(250)
        let expiredWater = try XCTUnwrap(store.state.nutrition.water.first)
        store.removeWater(expiredWater.id, at: expiredAt)
        let ingredient = try XCTUnwrap(store.makeRecipeIngredient(food: food, quantity: 100, unit: "g"))
        let expiredRecipeID = try XCTUnwrap(store.saveRecipe(name: "Expired recipe", ingredients: [ingredient], yieldAmount: 1, yieldUnit: "servings"))
        store.deleteRecipe(expiredRecipeID, at: expiredAt)

        XCTAssertTrue(store.logFood(food, meal: meal, quantity: 50, unit: "g", confirmed: true))
        let permanentLog = try XCTUnwrap(store.state.nutrition.logs.first(where: { $0.id != expiredLog.id }))
        store.deleteFoodLog(permanentLog.id)
        store.permanentlyDeleteFoodLog(permanentLog.id)

        let reopened = LogbookStore(repository: repository)
        XCTAssertFalse(reopened.state.nutrition.logs.contains(where: { $0.id == expiredLog.id }), "Expired food deletion must be purged and saved on repository reopen")
        XCTAssertFalse(reopened.state.nutrition.logs.contains(where: { $0.id == permanentLog.id }), "Explicit permanent deletion must remain deleted after reopen")
        XCTAssertFalse(reopened.state.nutrition.water.contains(where: { $0.id == expiredWater.id }), "Expired water deletion must be purged on repository reopen")
        XCTAssertFalse(reopened.state.nutrition.recipes?.contains(where: { $0.id == expiredRecipeID }) == true, "Expired recipe deletion must be purged on repository reopen")
    }

    func testBarcodeUnknownResponseIsNotConvertedIntoAnAssociatedFood() throws {
        let data = Data(#"{"code":"0000000000000","status":0,"status_verbose":"product not found"}"#.utf8)
        XCTAssertNil(try FoodCatalogService.parseBarcodeResponse(data, requestedCode: "0000000000000"))
    }

    func testBarcodeProductRetainsProviderIdentityAndOnlyVerifiedGramServing() throws {
        let payload = #"{"code":"3017620422003","status":1,"product":{"code":"3017620422003","product_name":"QA hazelnut spread","brands":"Example","serving_size":"30 g","serving_quantity":30,"nutriments":{"energy-kcal_100g":539,"proteins_100g":5.4,"carbohydrates_100g":57.5,"fat_100g":30.9}}}"#
        let food = try XCTUnwrap(FoodCatalogService.parseBarcodeResponse(Data(payload.utf8), requestedCode: "3017620422003"))
        XCTAssertEqual(food.barcode, "3017620422003")
        XCTAssertEqual(food.source, "Open Food Facts · community-contributed")
        XCTAssertEqual(food.multiplier(for: 1, unit: "serving") ?? -1, 0.3, accuracy: 0.0001)
        XCTAssertEqual(food.multiplier(for: 30, unit: "g") ?? -1, 0.3, accuracy: 0.0001)

        let unverifiedServing = #"{"code":"3017620422003","status":1,"product":{"code":"3017620422003","product_name":"QA food","serving_size":"1 cup","serving_quantity":30,"nutriments":{"energy-kcal_100g":100,"proteins_100g":1,"carbohydrates_100g":2,"fat_100g":3}}}"#
        let unverified = try XCTUnwrap(FoodCatalogService.parseBarcodeResponse(Data(unverifiedServing.utf8), requestedCode: "3017620422003"))
        XCTAssertNil(unverified.multiplier(for: 1, unit: "serving"), "A serving quantity without a gram unit cannot authorize a gram conversion")
    }

    func testLegacyNutritionPayloadDecodesWithoutNewFoodFields() throws {
        let encoded = try JSONEncoder.logbook.encode(NutritionState())
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        object.removeValue(forKey: "targetHistory")
        object.removeValue(forKey: "favoriteFoodIDs")
        object.removeValue(forKey: "recipes")
        object.removeValue(forKey: "waterGoalMilliliters")
        object.removeValue(forKey: "calorieTolerance")
        let legacyData = try JSONSerialization.data(withJSONObject: object)
        let decoded = try JSONDecoder.logbook.decode(NutritionState.self, from: legacyData)
        XCTAssertNil(decoded.targetHistory)
        XCTAssertNil(decoded.recipes)

        let oldWater = try JSONDecoder.logbook.decode(WaterLog.self, from: Data(#"{"id":"legacy-water","date":"2026-11-08","milliliters":250}"#.utf8))
        let oldRecipe = try JSONDecoder.logbook.decode(FoodRecipe.self, from: Data(#"{"id":"legacy-recipe","name":"Legacy","ingredients":[],"yieldAmount":1,"yieldUnit":"servings"}"#.utf8))
        XCTAssertNil(oldWater.deletedAt)
        XCTAssertNil(oldRecipe.deletedAt)
    }

    func testWorkoutSetCanBeLoggedAndFinishedThenReopened() throws {
        let repository = temporaryRepository()
        let store = LogbookStore(repository: repository)
        let templateID = try XCTUnwrap(store.addTemplate(name: "Upper A"))
        let exercise = ExerciseDefinition(id: "test-bench", name: "Bench Press", group: "Chest", equipment: "Barbell")
        store.appendExercise(exercise, toTemplate: templateID)
        let template = try XCTUnwrap(store.state.training.templates.first)
        store.startWorkout(template)

        let active = try XCTUnwrap(store.state.training.activeSession)
        let row = try XCTUnwrap(active.exercises.first)
        XCTAssertFalse(row.sets.isEmpty)
        for plannedSet in row.sets {
            store.updateSet(exerciseID: row.id, setID: plannedSet.id, weightKg: 60, reps: 8)
            XCTAssertTrue(store.toggleSet(exerciseID: row.id, setID: plannedSet.id))
        }
        XCTAssertEqual(store.finishWorkout(confirmIncomplete: false), -1)

        let reopened = LogbookStore(repository: repository)
        XCTAssertNil(reopened.state.training.activeSession)
        let saved = try XCTUnwrap(reopened.state.training.completedSessions.first)
        XCTAssertEqual(saved.templateName, "Upper A")
        XCTAssertEqual(saved.exercises.first?.sets.first?.weightKg, 60)
        XCTAssertEqual(saved.exercises.first?.sets.first?.reps, 8)
        XCTAssertEqual(saved.exercises.first?.sets.first?.completed, true)
    }

    func testProgramsKeepIndependentFlexibleRotationsAndOutOfOrderCompletion() throws {
        let repository = temporaryRepository()
        let store = LogbookStore(repository: repository)
        let firstProgram = try XCTUnwrap(store.state.training.activeProgram?.id)

        var firstProgramTemplateIDs: [UUID] = []
        for number in 1...10 {
            firstProgramTemplateIDs.append(try XCTUnwrap(store.addTemplate(name: "A\(number)")))
        }
        XCTAssertEqual(store.state.training.activeProgram?.templateIDs.count, 10, "Programs support flexible rotations longer than eight workouts")
        XCTAssertEqual(store.state.training.scheduledTemplate?.id, firstProgramTemplateIDs[0])

        XCTAssertTrue(store.skipScheduledWorkout())
        XCTAssertTrue(store.skipScheduledWorkout())
        XCTAssertEqual(store.state.training.scheduledTemplate?.id, firstProgramTemplateIDs[2])
        XCTAssertTrue(store.state.training.completedSessions.isEmpty, "Skipping advances without creating workout history")

        let secondProgram = try XCTUnwrap(store.addProgram(name: "Strength B"))
        let b1 = try XCTUnwrap(store.addTemplate(name: "B1"))
        _ = try XCTUnwrap(store.addTemplate(name: "B2"))
        XCTAssertEqual(store.state.training.scheduledTemplate?.id, b1)

        store.setActiveProgram(firstProgram)
        XCTAssertEqual(store.state.training.scheduledTemplate?.id, firstProgramTemplateIDs[2])
        let outOfOrder = try XCTUnwrap(store.state.training.templates.first { $0.id == firstProgramTemplateIDs[7] })
        store.startWorkout(outOfOrder)
        XCTAssertEqual(store.finishWorkout(confirmIncomplete: false), -1)
        XCTAssertEqual(store.state.training.scheduledTemplate?.id, firstProgramTemplateIDs[2], "Finishing a non-next workout leaves the scheduled item unchanged")

        let scheduled = try XCTUnwrap(store.state.training.templates.first { $0.id == firstProgramTemplateIDs[2] })
        store.startWorkout(scheduled)
        XCTAssertEqual(store.finishWorkout(confirmIncomplete: false), -1)
        XCTAssertEqual(store.state.training.scheduledTemplate?.id, firstProgramTemplateIDs[3])

        store.setActiveProgram(secondProgram)
        XCTAssertEqual(store.state.training.scheduledTemplate?.id, b1, "Switching programs restores its own saved rotation")
        let reopened = LogbookStore(repository: repository)
        XCTAssertEqual(reopened.state.training.activeProgram?.id, secondProgram)
        XCTAssertEqual(reopened.state.training.scheduledTemplate?.id, b1)
        XCTAssertEqual(reopened.state.training.programs?.first(where: { $0.id == firstProgram })?.rotationIndex, 3)
    }

    func testScheduledIncompleteWorkoutAdvancesButDiscardDoesNot() throws {
        let store = LogbookStore(repository: temporaryRepository())
        let firstID = try XCTUnwrap(store.addTemplate(name: "Scheduled A"))
        let secondID = try XCTUnwrap(store.addTemplate(name: "Scheduled B"))
        let exercise = ExerciseDefinition(id: "schedule-test", name: "Squat", group: "Legs", equipment: "Barbell")
        store.appendExercise(exercise, toTemplate: firstID)
        let first = try XCTUnwrap(store.state.training.templates.first { $0.id == firstID })

        store.startWorkout(first)
        let active = try XCTUnwrap(store.state.training.activeSession)
        XCTAssertGreaterThan(store.finishWorkout(confirmIncomplete: false), 0)
        XCTAssertEqual(store.finishWorkout(confirmIncomplete: true), -1)
        XCTAssertEqual(store.state.training.scheduledTemplate?.id, secondID, "Confirmed partial save still completes the scheduled slot")

        let programID = try XCTUnwrap(store.state.training.activeProgram?.id)
        store.moveTemplate(secondID, toProgram: programID, at: 0)
        XCTAssertEqual(store.state.training.scheduledTemplate?.id, secondID)
        let second = try XCTUnwrap(store.state.training.templates.first { $0.id == secondID })
        store.startWorkout(second)
        store.discardWorkout()
        XCTAssertEqual(store.state.training.scheduledTemplate?.id, secondID)
        XCTAssertTrue(store.state.training.completedSessions.contains { $0.id == active.id })
    }

    func testSwitchingProgramDuringDraftFinishesAgainstOriginProgram() throws {
        let store = LogbookStore(repository: temporaryRepository())
        let originID = try XCTUnwrap(store.state.training.activeProgram?.id)
        let a1 = try XCTUnwrap(store.addTemplate(name: "Origin A1"))
        _ = try XCTUnwrap(store.addTemplate(name: "Origin A2"))
        let a = try XCTUnwrap(store.state.training.templates.first { $0.id == a1 })
        store.startWorkout(a)
        XCTAssertEqual(store.state.training.activeSession?.programID, originID)

        let otherID = try XCTUnwrap(store.addProgram(name: "Other"))
        let otherTemplateID = try XCTUnwrap(store.addTemplate(name: "Other 1"))
        store.setActiveProgram(originID)
        store.setActiveProgram(otherID)
        XCTAssertEqual(store.finishWorkout(confirmIncomplete: false), -1)
        XCTAssertEqual(store.state.training.activeProgram?.id, otherID)
        XCTAssertEqual(store.state.training.scheduledTemplate?.id, otherTemplateID)
        XCTAssertEqual(store.state.training.programs?.first(where: { $0.id == originID })?.rotationIndex, 1)
    }

    func testLegacySingleRotationMigratesWithoutResettingItsUpcomingWorkout() throws {
        let repository = temporaryRepository()
        var legacy = LogbookState.empty
        let first = WorkoutTemplate(name: "Legacy A")
        let second = WorkoutTemplate(name: "Legacy B")
        legacy.training.templates = [first, second]
        legacy.training.rotationIndex = 1
        legacy.training.programs = nil
        legacy.training.activeProgramID = nil
        try repository.save(legacy)

        let migrated = LogbookStore(repository: repository)
        XCTAssertEqual(migrated.state.training.availablePrograms.count, 1)
        XCTAssertEqual(migrated.state.training.activeProgram?.name, "Program 1")
        XCTAssertEqual(migrated.state.training.activeProgram?.templateIDs, [first.id, second.id])
        XCTAssertEqual(migrated.state.training.scheduledTemplate?.id, second.id)

        let reopened = LogbookStore(repository: repository)
        XCTAssertEqual(reopened.state.training.activeProgram?.id, migrated.state.training.activeProgram?.id)
        XCTAssertEqual(reopened.state.training.scheduledTemplate?.id, second.id)
    }

    func testEstimatedOneRepMaxUsesFirstWorkoutAsBaselineAndOnlyOneRecordPerExerciseWorkout() throws {
        let repository = temporaryRepository()
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let baseline = completedSession(at: start, exerciseID: "bench", name: "Bench Press", sets: [(50, 10), (60, 5)])
        let improvement = completedSession(at: start.addingTimeInterval(86_400), exerciseID: "bench", name: "Bench Press", sets: [(63, 5), (65, 5)])
        let noImprovement = completedSession(at: start.addingTimeInterval(172_800), exerciseID: "bench", name: "Bench Press", sets: [(60, 5)])
        var initial = LogbookState.empty
        initial.training.completedSessions = [baseline, improvement, noImprovement]
        try repository.save(initial)

        let store = LogbookStore(repository: repository)
        let records = store.state.training.personalRecordEvents
        XCTAssertEqual(records.count, 1, "The first workout is baseline; multiple better sets in one later workout produce one event")
        XCTAssertEqual(records.first?.sessionID, improvement.id)
        XCTAssertEqual(records.first?.estimatedOneRepMaxKg ?? 0, 65 * (1 + 5.0 / 30), accuracy: 0.001)
        XCTAssertEqual(records.first?.previousBestKg ?? 0, 60 * (1 + 5.0 / 30), accuracy: 0.001)
    }

    func testCompletingLiveWorkoutSurfacesImprovementOverHistoricalBaseline() throws {
        let repository = temporaryRepository()
        let baselineDate = Date.now.addingTimeInterval(-86_400)
        let baseline = completedSession(at: baselineDate, exerciseID: "live-bench", name: "Bench Press", sets: [(60, 8)])
        let exercise = ExerciseDefinition(id: "live-bench", name: "Bench Press", group: "Chest", equipment: "Barbell")
        let template = WorkoutTemplate(name: "Upper Body", exercises: [
            PlannedExercise(exerciseID: exercise.id, name: exercise.name, muscle: exercise.group, equipment: exercise.equipment, sets: [PlannedSet()])
        ])
        var initial = LogbookState.empty
        initial.training.exercises = [exercise]
        initial.training.templates = [template]
        let program = WorkoutProgram(name: "Strength", templateIDs: [template.id])
        initial.training.programs = [program]
        initial.training.activeProgramID = program.id
        initial.training.completedSessions = [baseline]
        try repository.save(initial)

        let store = LogbookStore(repository: repository)
        store.startWorkout(template)
        let active = try XCTUnwrap(store.state.training.activeSession)
        let activeExercise = try XCTUnwrap(active.exercises.first)
        let workingSet = try XCTUnwrap(activeExercise.sets.first)
        store.updateSet(exerciseID: activeExercise.id, setID: workingSet.id, weightKg: 80, reps: 8)
        XCTAssertTrue(store.toggleSet(exerciseID: activeExercise.id, setID: workingSet.id))
        XCTAssertEqual(store.finishWorkout(confirmIncomplete: false), -1)

        let saved = try XCTUnwrap(store.state.training.completedSessions.first { $0.id == active.id })
        let record = try XCTUnwrap(store.state.training.personalRecordEvents.first { $0.sessionID == saved.id })
        XCTAssertEqual(record.exerciseID, "live-bench")
        XCTAssertEqual(record.estimatedOneRepMaxKg, 80 * (1 + 8.0 / 30), accuracy: 0.001)
        XCTAssertEqual(record.previousBestKg, 60 * (1 + 8.0 / 30), accuracy: 0.001)
    }

    func testHistoricalEditsDeletionAndRestoreRecalculatePersonalRecords() throws {
        let repository = temporaryRepository()
        let start = Date(timeIntervalSince1970: 1_800_100_000)
        let baseline = completedSession(at: start, exerciseID: "squat", name: "Squat", sets: [(80, 8)])
        let next = completedSession(at: start.addingTimeInterval(86_400), exerciseID: "squat", name: "Squat", sets: [(90, 8)])
        var initial = LogbookState.empty
        initial.training.completedSessions = [baseline, next]
        try repository.save(initial)
        let store = LogbookStore(repository: repository)
        XCTAssertEqual(store.state.training.personalRecordEvents.count, 1)

        let editableSet = try XCTUnwrap(next.exercises.first?.sets.first)
        let exercise = try XCTUnwrap(next.exercises.first)
        store.updateCompletedWorkoutSet(sessionID: next.id, exerciseID: exercise.id, setID: editableSet.id, weightKg: 70, reps: 8, completed: true)
        XCTAssertTrue(store.state.training.personalRecordEvents.isEmpty, "Editing historical sets recalculates derived records immediately")

        store.updateCompletedWorkoutSet(sessionID: next.id, exerciseID: exercise.id, setID: editableSet.id, weightKg: 95, reps: 8, completed: true)
        XCTAssertEqual(store.state.training.personalRecordEvents.count, 1)
        let deletedAt = Date(timeIntervalSince1970: 1_800_200_000)
        store.deleteCompletedWorkout(next.id, at: deletedAt)
        XCTAssertTrue(store.state.training.visibleCompletedSessions.contains { $0.id == next.id } == false)
        XCTAssertTrue(store.state.training.personalRecordEvents.isEmpty)
        XCTAssertEqual(store.state.training.recentlyDeletedSessions(asOf: deletedAt).map(\.id), [next.id])

        XCTAssertTrue(store.restoreDeletedWorkout(next.id, at: deletedAt.addingTimeInterval(29 * 24 * 60 * 60)))
        XCTAssertEqual(store.state.training.personalRecordEvents.count, 1, "Restoring a workout recomputes its PR")
        store.deleteCompletedWorkout(next.id, at: deletedAt)
        store.permanentlyDeleteWorkout(next.id)
        XCTAssertNil(store.state.training.completedSessions.first { $0.id == next.id })
    }

    func testRecentlyDeletedWorkoutExpiresAfterThirtyDays() throws {
        let repository = temporaryRepository()
        let completed = completedSession(at: Date(timeIntervalSince1970: 1_800_300_000), exerciseID: "deadlift", name: "Deadlift", sets: [(100, 5)])
        var initial = LogbookState.empty
        initial.training.completedSessions = [completed]
        try repository.save(initial)
        let store = LogbookStore(repository: repository)
        let deletionDate = Date(timeIntervalSince1970: 1_800_400_000)
        store.deleteCompletedWorkout(completed.id, at: deletionDate)
        XCTAssertFalse(store.restoreDeletedWorkout(completed.id, at: deletionDate.addingTimeInterval(30 * 24 * 60 * 60)))
        XCTAssertTrue(store.state.training.recentlyDeletedSessions(asOf: deletionDate.addingTimeInterval(30 * 24 * 60 * 60)).isEmpty)
        store.purgeExpiredDeletedWorkouts(asOf: deletionDate.addingTimeInterval(30 * 24 * 60 * 60))
        XCTAssertTrue(store.state.training.completedSessions.isEmpty)
    }

    func testExerciseTrackingModesUseTheirOwnMeasurementsWithoutFalsePRs() throws {
        let store = LogbookStore(repository: temporaryRepository())
        let modes: [(String, ExerciseTrackingMode)] = [
            ("reps-row", .repsOnly),
            ("hold", .duration),
            ("carry", .weightAndDistance)
        ]
        let exercises = modes.map { id, mode in
            PlannedExercise(id: UUID(), exerciseID: id, name: id, muscle: "Test", equipment: "Other", sets: [PlannedSet()], trackingMode: mode)
        }
        store.startWorkout(WorkoutTemplate(name: "Alternate tracking", exercises: exercises))
        let session = try XCTUnwrap(store.state.training.activeSession)
        let reps = try XCTUnwrap(session.exercises.first { $0.trackingMode == .repsOnly })
        let duration = try XCTUnwrap(session.exercises.first { $0.trackingMode == .duration })
        let distance = try XCTUnwrap(session.exercises.first { $0.trackingMode == .weightAndDistance })

        store.updateSet(exerciseID: reps.id, setID: reps.sets[0].id, weightKg: nil, reps: 12)
        XCTAssertTrue(store.toggleSet(exerciseID: reps.id, setID: reps.sets[0].id))

        XCTAssertFalse(store.toggleSet(exerciseID: duration.id, setID: duration.sets[0].id))
        store.updateSetDuration(exerciseID: duration.id, setID: duration.sets[0].id, seconds: 40)
        XCTAssertTrue(store.toggleSet(exerciseID: duration.id, setID: duration.sets[0].id))

        XCTAssertFalse(store.toggleSet(exerciseID: distance.id, setID: distance.sets[0].id))
        store.updateSetDistance(exerciseID: distance.id, setID: distance.sets[0].id, weightKg: 20, distanceMeters: 100)
        XCTAssertTrue(store.toggleSet(exerciseID: distance.id, setID: distance.sets[0].id))
        XCTAssertEqual(store.finishWorkout(confirmIncomplete: true), -1)
        XCTAssertTrue(store.state.training.personalRecordEvents.isEmpty, "Non-weight-and-reps activities do not produce estimated 1RM records")
    }

    func testProgressionSuggestionOnlyChangesSessionAfterExplicitAcceptance() throws {
        let repository = temporaryRepository()
        let exerciseID = "progression-acceptance"
        let previous = completedSession(at: Date(timeIntervalSince1970: 1_800_000_000), exerciseID: exerciseID, name: "Bench Press", sets: [(60, 8)])
        var seededState = LogbookState.empty
        seededState.training.completedSessions = [previous]
        try repository.save(seededState)
        let store = LogbookStore(repository: repository)

        let exercise = PlannedExercise(exerciseID: exerciseID, name: "Bench Press", muscle: "Chest", equipment: "Barbell", sets: [PlannedSet(), PlannedSet()])
        store.startWorkout(WorkoutTemplate(name: "Progression", exercises: [exercise]))
        let active = try XCTUnwrap(store.state.training.activeSession)
        let row = try XCTUnwrap(active.exercises.first)

        XCTAssertTrue(row.sets.allSatisfy { $0.weightKg == nil }, "A suggestion does not silently prefill the user's workout")
        store.declineProgressionSuggestion(exerciseID: row.id)
        XCTAssertTrue(store.state.training.activeSession?.exercises.first?.sets.allSatisfy { $0.weightKg == nil } == true,
                      "Declining a suggestion leaves planned set values unchanged")
        XCTAssertEqual(store.state.training.activeSession?.declinedProgressionExerciseIDs, [row.id])
        store.discardWorkout()
        store.startWorkout(WorkoutTemplate(name: "Progression", exercises: [exercise]))
        let newRow = try XCTUnwrap(store.state.training.activeSession?.exercises.first)
        XCTAssertFalse(store.acceptProgressionSuggestion(exerciseID: newRow.id, weightKg: 0))
        XCTAssertTrue(store.acceptProgressionSuggestion(exerciseID: newRow.id, weightKg: 62.5))
        XCTAssertTrue(store.state.training.activeSession?.exercises.first?.sets.allSatisfy { $0.weightKg == 62.5 } == true)

        store.updateSet(exerciseID: newRow.id, setID: newRow.sets[0].id, weightKg: 65, reps: 8)
        XCTAssertFalse(store.acceptProgressionSuggestion(exerciseID: newRow.id, weightKg: 67.5), "An accepted set cannot be overwritten by a later suggestion")
    }

    func testZeroOrInvalidRepsCannotCompleteASetOrCreateAnEstimatedOneRepMaxRecord() throws {
        let repository = temporaryRepository()
        let store = LogbookStore(repository: repository)
        let planned = PlannedExercise(exerciseID: "invalid-reps", name: "Press", muscle: "Chest", equipment: "Barbell", sets: [PlannedSet()])
        store.startWorkout(WorkoutTemplate(name: "Invalid entry", exercises: [planned]))
        let active = try XCTUnwrap(store.state.training.activeSession)
        let row = try XCTUnwrap(active.exercises.first)
        let set = try XCTUnwrap(row.sets.first)
        store.updateSet(exerciseID: row.id, setID: set.id, weightKg: 100, reps: 0)
        XCTAssertFalse(store.toggleSet(exerciseID: row.id, setID: set.id))
        XCTAssertEqual(store.state.training.activeSession?.exercises.first?.sets.first?.reps, 0)
        XCTAssertEqual(store.state.training.activeSession?.exercises.first?.sets.first?.completed, false)

        let date = Date(timeIntervalSince1970: 1_800_000_000)
        var historical = LogbookState.empty
        historical.training.completedSessions = [
            completedSession(at: date, exerciseID: "invalid-reps", name: "Press", sets: [(100, 0)]),
            completedSession(at: date.addingTimeInterval(86_400), exerciseID: "invalid-reps", name: "Press", sets: [(90, 10)])
        ]
        try repository.save(historical)
        let history = LogbookStore(repository: repository)
        XCTAssertTrue(history.state.training.personalRecordEvents.isEmpty, "A zero-rep historical set is excluded, and the next valid workout establishes baseline")
    }

    func testRestTimerPauseExtensionResumeAndSkipUseAbsoluteTime() {
        let start = Date(timeIntervalSince1970: 10_000)
        var timer = WorkoutRestTimer()
        XCTAssertEqual(timer.remainingSeconds(at: start), 0)

        timer.start(at: start)
        XCTAssertEqual(timer.remainingSeconds(at: start), 90)
        XCTAssertEqual(timer.remainingSeconds(at: start.addingTimeInterval(20)), 70)
        timer.addFifteenSeconds(at: start.addingTimeInterval(20))
        XCTAssertEqual(timer.remainingSeconds(at: start.addingTimeInterval(20)), 85)
        XCTAssertEqual(timer.currentDurationSeconds, 105)

        timer.pause(at: start.addingTimeInterval(20))
        XCTAssertTrue(timer.isPaused)
        XCTAssertEqual(timer.remainingSeconds(at: start.addingTimeInterval(60)), 85)
        timer.addFifteenSeconds(at: start.addingTimeInterval(60))
        XCTAssertEqual(timer.remainingSeconds(at: start.addingTimeInterval(60)), 100)

        timer.resume(at: start.addingTimeInterval(120))
        XCTAssertFalse(timer.isPaused)
        XCTAssertEqual(timer.remainingSeconds(at: start.addingTimeInterval(120)), 100)
        timer.skip(at: start.addingTimeInterval(121))
        XCTAssertEqual(timer.remainingSeconds(at: start.addingTimeInterval(121)), 0)
        XCTAssertEqual(timer.remainingSeconds(at: start.addingTimeInterval(180)), 0)
    }

    func testSupersetRestBeginsOnlyAfterEveryExerciseCompletesTheRound() throws {
        let repository = temporaryRepository()
        let store = LogbookStore(repository: repository)
        let group = UUID()
        var first = PlannedExercise(exerciseID: "test-a", name: "Press", muscle: "Chest", equipment: "Barbell", sets: [PlannedSet()])
        first.supersetID = group
        var second = PlannedExercise(exerciseID: "test-b", name: "Row", muscle: "Back", equipment: "Cable", sets: [PlannedSet()])
        second.supersetID = group
        let template = WorkoutTemplate(name: "A/B", exercises: [first, second])
        store.startWorkout(template)
        let active = try XCTUnwrap(store.state.training.activeSession)
        let press = try XCTUnwrap(active.exercises.first)
        let row = try XCTUnwrap(active.exercises.last)

        store.updateSet(exerciseID: press.id, setID: press.sets[0].id, weightKg: 30, reps: 10)
        XCTAssertTrue(store.toggleSet(exerciseID: press.id, setID: press.sets[0].id))
        XCTAssertNil(store.state.training.activeSession?.restTimer?.endsAt, "Do not rest between exercises within a superset round")

        store.updateSet(exerciseID: row.id, setID: row.sets[0].id, weightKg: 30, reps: 10)
        XCTAssertTrue(store.toggleSet(exerciseID: row.id, setID: row.sets[0].id))
        XCTAssertGreaterThan(try XCTUnwrap(store.state.training.activeSession?.restTimer?.endsAt), .now)
    }

    func testRestTimerUsesExerciseOverrideAndSurvivesRepositoryReopen() throws {
        let repository = temporaryRepository()
        let store = LogbookStore(repository: repository)
        var planned = PlannedExercise(exerciseID: "timer-row", name: "Row", muscle: "Back", equipment: "Cable", sets: [PlannedSet()])
        planned.restSeconds = 45
        store.startWorkout(WorkoutTemplate(name: "Timer test", exercises: [planned]))

        let session = try XCTUnwrap(store.state.training.activeSession)
        let exercise = try XCTUnwrap(session.exercises.first)
        store.updateSet(exerciseID: exercise.id, setID: exercise.sets[0].id, weightKg: 40, reps: 8)
        XCTAssertTrue(store.toggleSet(exerciseID: exercise.id, setID: exercise.sets[0].id))

        let original = try XCTUnwrap(store.state.training.activeSession?.restTimer)
        XCTAssertEqual(original.baseDurationSeconds, 90)
        XCTAssertEqual(original.currentDurationSeconds, 45)
        let originalEnd = try XCTUnwrap(original.endsAt)
        let reopened = LogbookStore(repository: repository)
        let recovered = try XCTUnwrap(reopened.state.training.activeSession?.restTimer)
        let recoveredEnd = try XCTUnwrap(recovered.endsAt)
        XCTAssertLessThan(abs(recoveredEnd.timeIntervalSince(originalEnd)), 0.001)
        XCTAssertEqual(recovered.currentDurationSeconds, 45)
        XCTAssertGreaterThan(recovered.remainingSeconds(), 0)
    }

    func testOldActiveSessionPayloadDecodesWithoutRestTimerFields() throws {
        let repository = temporaryRepository()
        let store = LogbookStore(repository: repository)
        let templateID = try XCTUnwrap(store.addTemplate(name: "Legacy"))
        let exercise = ExerciseDefinition(id: "legacy-row", name: "Row", group: "Back", equipment: "Cable")
        store.appendExercise(exercise, toTemplate: templateID)
        store.startWorkout(try XCTUnwrap(store.state.training.templates.first))

        let encoded = try JSONEncoder.logbook.encode(store.state)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        var training = try XCTUnwrap(object["training"] as? [String: Any])
        var active = try XCTUnwrap(training["activeSession"] as? [String: Any])
        active.removeValue(forKey: "restTimer")
        if var exercises = active["exercises"] as? [[String: Any]] {
            exercises = exercises.map { row in
                var row = row
                row.removeValue(forKey: "restSeconds")
                return row
            }
            active["exercises"] = exercises
        }
        training["activeSession"] = active
        object["training"] = training
        let legacyPayload = try JSONSerialization.data(withJSONObject: object)

        let reopened = try JSONDecoder.logbook.decode(LogbookState.self, from: legacyPayload)
        XCTAssertNil(reopened.training.activeSession?.restTimer)
        XCTAssertNil(reopened.training.activeSession?.exercises.first?.restSeconds)
    }

    func testDatePersistenceKeepsSubsecondsAndReadsLegacyWholeSecondDates() throws {
        let preciseDate = Date(timeIntervalSince1970: 1_800_000_000.123)
        var state = LogbookState.empty
        state.lastModified = preciseDate

        let encoded = try JSONEncoder.logbook.encode(state)
        let encodedText = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertTrue(encodedText.contains(".123"), "New state files retain fractional seconds for timer recovery")
        let roundTrip = try JSONDecoder.logbook.decode(LogbookState.self, from: encoded)
        XCTAssertLessThan(abs(roundTrip.lastModified.timeIntervalSince(preciseDate)), 0.001)

        var legacyObject = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        let legacyDate = Date(timeIntervalSince1970: 1_800_000_000)
        legacyObject["lastModified"] = "2027-01-15T08:00:00Z"
        let legacyData = try JSONSerialization.data(withJSONObject: legacyObject)
        let legacyRoundTrip = try JSONDecoder.logbook.decode(LogbookState.self, from: legacyData)
        XCTAssertLessThan(abs(legacyRoundTrip.lastModified.timeIntervalSince(legacyDate)), 0.001)
    }

    func testApprovedThemeAndWidgetInventoryCounts() {
        XCTAssertEqual(LogbookTheme.allCases.count, 17)
        XCTAssertEqual(LogbookTheme.allCases.filter { $0 != .defaultTheme }.count, 16, "Preserve all existing themes while staging v2 Default")
        XCTAssertEqual(WidgetKind.allCases.count, 38)
        XCTAssertEqual(HomeState().theme, .defaultTheme)
        XCTAssertEqual(HomeState().pages.map(\.name), ["Daily", "Training", "Food", "Progress & History"])
        XCTAssertEqual(LogbookTheme.defaultTheme.tokens.cardOpacity, 0.86, accuracy: 0.001)
        XCTAssertEqual(LogbookTheme.premiumGlass.tokens.cardOpacity, 0.78, accuracy: 0.001)
    }

    func testDailyDefaultUsesApprovedWidgetSizesAndPositions() throws {
        let widgets = try XCTUnwrap(HomeState.defaultPages.first?.widgets.sorted {
            $0.row == $1.row ? $0.column < $1.column : $0.row < $1.row
        })
        XCTAssertEqual(widgets.map(\.kind), [.calories, .nextWorkout, .trainingStreak, .vitals])
        XCTAssertEqual(widgets.map(\.size), [.large, .medium, .small, .small])
        XCTAssertEqual(widgets.map { [$0.row, $0.column] }, [[0, 0], [2, 0], [3, 0], [3, 1]])
        XCTAssertEqual(widgets[0].variant, "Calories & Macros Remaining")
        XCTAssertEqual(widgets[2].variant, "Habits Streak")
        XCTAssertEqual(widgets[3].variant, "Daily Check-in")
    }

    func testMigrationUpdatesOnlyUntouchedPreviousDailyDefault() throws {
        let repository = temporaryRepository()
        var legacy = LogbookState.empty
        legacy.home.pages[0] = previousDailyPage(id: legacy.home.pages[0].id)
        legacy.home.pages[2].name = "My Food Page"
        legacy.home.theme = .oceanBreeze
        try repository.save(legacy)

        let migrated = LogbookStore(repository: repository).state
        let daily = try XCTUnwrap(migrated.home.pages.first)
        XCTAssertEqual(daily.name, "Daily")
        XCTAssertEqual(daily.widgets.map(\.size), [.large, .medium, .small, .small])
        XCTAssertEqual(daily.widgets.map { [$0.row, $0.column] }, [[0, 0], [2, 0], [3, 0], [3, 1]])
        XCTAssertEqual(migrated.home.theme, .oceanBreeze)
        XCTAssertEqual(migrated.home.pages[1], legacy.home.pages[1])
        XCTAssertEqual(migrated.home.pages[2], legacy.home.pages[2])
        XCTAssertEqual(migrated.home.pages[3], legacy.home.pages[3])
        XCTAssertEqual(migrated.home.pages[0].id, legacy.home.pages[0].id)
        XCTAssertEqual(migrated.home.pages[0].widgets.map(\.id), legacy.home.pages[0].widgets.map(\.id))
    }

    func testMigrationDoesNotOverwriteCustomizedDailyLayout() throws {
        let repository = temporaryRepository()
        var legacy = LogbookState.empty
        legacy.home.pages[0] = previousDailyPage(id: legacy.home.pages[0].id)
        legacy.home.pages[0].widgets[3].row = 3
        try repository.save(legacy)

        let loaded = LogbookStore(repository: repository).state
        XCTAssertEqual(loaded.home.pages, legacy.home.pages)
    }

    func testMigrationRelabelsOnlyUntouchedNamedCaloriesWidgetAndKeepsItsIdentity() throws {
        let repository = temporaryRepository()
        var legacy = LogbookState.empty
        legacy.home.pages[0] = previousNamedDailyPage(id: legacy.home.pages[0].id)
        try repository.save(legacy)

        let loaded = LogbookStore(repository: repository).state
        let daily = try XCTUnwrap(loaded.home.pages.first)
        XCTAssertEqual(daily.widgets.first(where: { $0.kind == .calories })?.variant, "Calories & Macros Remaining")
        XCTAssertEqual(daily.widgets.map(\.id), legacy.home.pages[0].widgets.map(\.id))
    }

    func testDailyHabitDenominatorTreatsNoDueSupplementsAsNeutral() {
        var state = LogbookState.empty
        let today = Calendar.current.startOfDay(for: .now)
        let day = LocalDay.string(today)
        let sleepEnd = today.addingTimeInterval(8 * 60 * 60)
        state.checkins.sleep = [SleepLog(wakeDate: day, bedtime: today, wakeTime: sleepEnd)]
        state.checkins.weights = [WeightLog(date: day, kilograms: 80)]
        let weekday = Calendar.current.component(.weekday, from: today)
        state.checkins.supplements = [Supplement(name: "Weekday-only", schedule: "weekdays", weekdays: [weekday == 1 ? 2 : 1])]

        let metrics = DailyHomeMetrics(state: state, date: today)
        XCTAssertEqual(metrics.eligibleCount, 2)
        XCTAssertEqual(metrics.completedCount, 2)
        XCTAssertTrue(metrics.supplementsComplete)
        XCTAssertTrue(metrics.isPerfectDay)
    }

    func testDailyHabitCompletionRequiresEveryDueSupplementAndKeepsYesterdayStreak() {
        var state = LogbookState.empty
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let supplement = Supplement(name: "Daily", schedule: "daily")
        state.checkins.supplements = [supplement]
        for offset in 1...3 {
            guard let dayDate = calendar.date(byAdding: .day, value: -offset, to: today),
                  let bedtime = calendar.date(byAdding: .hour, value: -8, to: dayDate),
                  let wake = calendar.date(byAdding: .hour, value: 8, to: dayDate) else { continue }
            let key = LocalDay.string(dayDate)
            state.checkins.sleep.append(SleepLog(wakeDate: key, bedtime: bedtime, wakeTime: wake))
            state.checkins.weights.append(WeightLog(date: key, kilograms: 80))
            state.checkins.doses.append(SupplementDose(supplementID: supplement.id, supplementName: supplement.name, date: key, taken: true, explicitlyMarked: true))
        }
        let todayKey = LocalDay.string(today)
        state.checkins.sleep.append(SleepLog(wakeDate: todayKey, bedtime: today, wakeTime: today.addingTimeInterval(8 * 60 * 60)))
        state.checkins.weights.append(WeightLog(date: todayKey, kilograms: 80))

        let metrics = DailyHomeMetrics(state: state, date: today)
        XCTAssertEqual(metrics.eligibleCount, 3)
        XCTAssertEqual(metrics.completedCount, 2)
        XCTAssertFalse(metrics.supplementsComplete)
        XCTAssertFalse(metrics.isPerfectDay)
        XCTAssertEqual(metrics.perfectDayStreak, 3, "An incomplete current day keeps the preceding consecutive perfect-day streak visible")
    }

    private func temporaryRepository() -> LogbookRepository {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("LogbookTests-\(UUID().uuidString)", isDirectory: true)
        return LogbookRepository(url: directory.appendingPathComponent("state.json"))
    }

    private func completedSession(at finishedAt: Date, exerciseID: String, name: String, sets performances: [(Double, Int)]) -> WorkoutSession {
        let exercise = WorkoutExercise(
            exerciseID: exerciseID,
            name: name,
            muscle: "Test",
            equipment: "Barbell",
            sets: performances.map { WorkoutSet(weightKg: $0.0, reps: $0.1, completed: true) },
            supersetID: nil
        )
        return WorkoutSession(
            templateName: name,
            templateVersion: 1,
            localDate: LocalDay.string(finishedAt),
            startedAt: finishedAt.addingTimeInterval(-3_600),
            finishedAt: finishedAt,
            exercises: [exercise]
        )
    }

    private func previousDailyPage(id: UUID) -> HomePage {
        HomePage(id: id, name: "Daily", widgets: [
            HomeWidget(kind: .calories, size: .medium, row: 0, column: 0),
            HomeWidget(kind: .nextWorkout, size: .medium, row: 1, column: 0),
            HomeWidget(kind: .trainingStreak, size: .small, row: 2, column: 0, variant: "Habits Streak"),
            HomeWidget(kind: .vitals, size: .small, row: 2, column: 1, variant: "Daily Check-in")
        ])
    }

    private func previousNamedDailyPage(id: UUID) -> HomePage {
        HomePage(id: id, name: "Daily", widgets: [
            HomeWidget(kind: .calories, size: .large, row: 0, column: 0, variant: "Calories & Protein Remaining"),
            HomeWidget(kind: .nextWorkout, size: .medium, row: 2, column: 0),
            HomeWidget(kind: .trainingStreak, size: .small, row: 3, column: 0, variant: "Habits Streak"),
            HomeWidget(kind: .vitals, size: .small, row: 3, column: 1, variant: "Daily Check-in")
        ])
    }
}
