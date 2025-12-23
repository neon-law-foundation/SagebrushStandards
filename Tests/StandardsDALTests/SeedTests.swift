import Fluent
import Foundation
import StandardsDAL
import Testing
import Vapor

@Suite("Seed Tests")
struct SeedTests {

    @Test("Verify seeds can be loaded and Neon Law Foundation exists")
    func testSeedsLoadAndNeonLawFoundationExists() async throws {
        try await TestUtilities.withApp { app, db in
            // Run seeds
            let seedCount = try await StandardsDALConfiguration.runSeeds(
                on: db,
                environment: app.environment,
                logger: app.logger
            )

            #expect(seedCount > 0, "Should have seeded at least one record")

            // Verify "Neon Law Foundation" entity exists
            let neonLawFoundation = try await Entity.query(on: db)
                .filter(\.$name == "Neon Law Foundation")
                .first()

            #expect(neonLawFoundation != nil, "Neon Law Foundation should exist in seeds")

            let neonLawFoundationID = try neonLawFoundation?.requireID()
            #expect(neonLawFoundationID != nil, "Neon Law Foundation should have valid ID")
        }
    }

    @Test("Create notation owned by Neon Law Foundation from seeds")
    func testCreateNotationOwnedByNeonLawFoundation() async throws {
        try await TestUtilities.withApp { app, db in
            // Run seeds to get Neon Law Foundation
            _ = try await StandardsDALConfiguration.runSeeds(
                on: db,
                environment: app.environment,
                logger: app.logger
            )

            // Find Neon Law Foundation
            let neonLawFoundation = try await Entity.query(on: db)
                .filter(\.$name == "Neon Law Foundation")
                .first()

            #expect(neonLawFoundation != nil, "Neon Law Foundation should exist")

            let ownerID = try neonLawFoundation!.requireID()

            // Create a notation owned by Neon Law Foundation
            let notation = Notation()
            notation.title = "NLF Notation"
            notation.description = "A notation owned by Neon Law Foundation"
            notation.respondentType = .person
            notation.markdownContent = "# NLF Document\n\nThis is owned by Neon Law Foundation."
            notation.frontmatter = ["organization": "Neon Law Foundation", "year": "2024"]
            notation.$owner.id = ownerID

            try await notation.save(on: db)
            let notationID = try notation.requireID()
            #expect(notationID > 0, "Notation should be created")

            // Verify the notation has the correct owner
            let fetched = try await Notation.find(notationID, on: db)
            #expect(fetched?.$owner.id == ownerID, "Owner should be Neon Law Foundation")

            // Load the owner relationship and verify
            try await fetched?.$owner.load(on: db)
            #expect(fetched?.owner?.name == "Neon Law Foundation", "Owner name should match")
        }
    }

    @Test("Verify entity types are seeded correctly")
    func testEntityTypesSeeded() async throws {
        try await TestUtilities.withApp { app, db in
            // Run seeds
            _ = try await StandardsDALConfiguration.runSeeds(
                on: db,
                environment: app.environment,
                logger: app.logger
            )

            // Verify specific entity types exist
            let nonProfitType = try await EntityType.query(on: db)
                .filter(\.$name == "501(c)(3) Non-Profit")
                .first()

            #expect(nonProfitType != nil, "501(c)(3) Non-Profit entity type should exist")

            let llcType = try await EntityType.query(on: db)
                .filter(\.$name == "Multi Member LLC")
                .first()

            #expect(llcType != nil, "Multi Member LLC entity type should exist")
        }
    }

    @Test("Verify jurisdictions are seeded correctly")
    func testJurisdictionsSeeded() async throws {
        try await TestUtilities.withApp { app, db in
            // Run seeds
            _ = try await StandardsDALConfiguration.runSeeds(
                on: db,
                environment: app.environment,
                logger: app.logger
            )

            // Verify Nevada jurisdiction exists
            let nevada = try await Jurisdiction.query(on: db)
                .filter(\.$name == "Nevada")
                .first()

            #expect(nevada != nil, "Nevada jurisdiction should exist")
            #expect(nevada?.jurisdictionType == .state, "Nevada should be a state")
        }
    }

    @Test("Verify all seeded entities have proper relationships")
    func testSeededEntitiesHaveRelationships() async throws {
        try await TestUtilities.withApp { app, db in
            // Run seeds
            _ = try await StandardsDALConfiguration.runSeeds(
                on: db,
                environment: app.environment,
                logger: app.logger
            )

            // Get Neon Law Foundation
            let neonLawFoundation = try await Entity.query(on: db)
                .filter(\.$name == "Neon Law Foundation")
                .first()

            #expect(neonLawFoundation != nil, "Neon Law Foundation should exist")

            // Load the entity type relationship
            try await neonLawFoundation?.$legalEntityType.load(on: db)

            #expect(
                neonLawFoundation?.legalEntityType.name == "501(c)(3) Non-Profit",
                "Neon Law Foundation should be a 501(c)(3) Non-Profit"
            )

            // Load the jurisdiction through entity type
            try await neonLawFoundation?.legalEntityType.$jurisdiction.load(on: db)

            #expect(
                neonLawFoundation?.legalEntityType.jurisdiction.name == "Nevada",
                "Entity type should be in Nevada jurisdiction"
            )
        }
    }

    @Test("Notation defaults to Neon Law Foundation owner when not specified")
    func testNotationDefaultsToNeonLawFoundation() async throws {
        try await TestUtilities.withApp { app, db in
            // Run seeds to get Neon Law Foundation
            _ = try await StandardsDALConfiguration.runSeeds(
                on: db,
                environment: app.environment,
                logger: app.logger
            )

            // Create a notation WITHOUT setting owner_id
            let notation = Notation()
            notation.title = "Default Owner Test"
            notation.description = "Testing default owner behavior"
            notation.respondentType = .person
            notation.markdownContent = "# Test"
            notation.frontmatter = [:]
            // NOT setting notation.$owner.id here

            // Set default owner before saving
            try await notation.setDefaultOwner(on: db)
            try await notation.save(on: db)

            let notationID = try notation.requireID()

            // Fetch and verify owner is Neon Law Foundation
            let fetched = try await Notation.find(notationID, on: db)
            #expect(fetched != nil, "Notation should be created")

            // Load owner relationship
            try await fetched?.$owner.load(on: db)

            #expect(fetched?.owner?.name == "Neon Law Foundation", "Default owner should be Neon Law Foundation")
        }
    }
}
