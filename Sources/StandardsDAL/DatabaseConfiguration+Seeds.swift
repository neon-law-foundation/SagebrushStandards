import Fluent
import FluentPostgresDriver
import FluentSQLiteDriver
import Foundation
import Logging
import Vapor

// MARK: - Seed Insert Functions

extension StandardsDALConfiguration {

    // MARK: - Jurisdiction

    static func insertJurisdiction(
        record: [String: Any],
        lookupFields: [String],
        database: Database
    ) async throws {
        let name = record["name"] as? String ?? ""
        let code = record["code"] as? String ?? ""

        if !lookupFields.isEmpty {
            var query = Jurisdiction.query(on: database)

            if lookupFields.contains("name") && !name.isEmpty {
                query = query.filter(\.$name == name)
            }

            if lookupFields.contains("code") && !code.isEmpty {
                query = query.filter(\.$code == code)
            }

            if let existing = try await query.first() {
                existing.name = name.isEmpty ? existing.name : name
                existing.code = code.isEmpty ? existing.code : code
                if let jurisdictionTypeString = record["jurisdiction_type"] as? String,
                   let jurisdictionType = JurisdictionType(rawValue: jurisdictionTypeString)
                {
                    existing.jurisdictionType = jurisdictionType
                }
                try await existing.save(on: database)
                return
            }
        }

        let jurisdiction = Jurisdiction()
        jurisdiction.code = code
        jurisdiction.name = name
        if let jurisdictionTypeString = record["jurisdiction_type"] as? String,
           let jurisdictionType = JurisdictionType(rawValue: jurisdictionTypeString)
        {
            jurisdiction.jurisdictionType = jurisdictionType
        } else {
            jurisdiction.jurisdictionType = .state
        }
        try await jurisdiction.save(on: database)
    }

    // MARK: - EntityType

    static func insertEntityType(
        record: [String: Any],
        lookupFields: [String],
        database: Database
    ) async throws {
        let name = record["name"] as? String ?? ""

        let jurisdictionId: Int32?
        if let jurisdictionDict = record["jurisdiction"] as? [String: Any],
           let jurisdictionName = jurisdictionDict["name"] as? String
        {
            let jurisdiction = try await Jurisdiction.query(on: database)
                .filter(\.$name == jurisdictionName)
                .first()
            jurisdictionId = jurisdiction?.id
        } else if let jurisdictionIdString = record["jurisdiction_id"] as? String {
            jurisdictionId = Int32(jurisdictionIdString)
        } else {
            jurisdictionId = nil
        }

        if !lookupFields.isEmpty,
           let jurisdictionId = jurisdictionId
        {
            if let existing = try await EntityType.query(on: database)
                .filter(\.$name == name)
                .filter(\.$jurisdiction.$id == jurisdictionId)
                .first()
            {
                try await existing.save(on: database)
                return
            }
        }

        let entityType = EntityType()
        entityType.name = name
        if let jurisdictionId = jurisdictionId {
            entityType.$jurisdiction.id = jurisdictionId
        }
        try await entityType.save(on: database)
    }

    // MARK: - Question

    static func insertQuestion(
        record: [String: Any],
        lookupFields: [String],
        database: Database
    ) async throws {
        if !lookupFields.isEmpty, let code = record["code"] as? String {
            if let existing = try await Question.query(on: database)
                .filter(\.$code == code)
                .first()
            {
                existing.prompt = record["prompt"] as? String ?? existing.prompt
                if let questionTypeString = record["question_type"] as? String,
                   let questionType = QuestionType(rawValue: questionTypeString)
                {
                    existing.questionType = questionType
                }
                existing.helpText = record["help_text"] as? String ?? existing.helpText
                existing.choices = record["choices"] as? [String: String] ?? existing.choices
                try await existing.save(on: database)
                return
            }
        }

        let question = Question()
        question.prompt = record["prompt"] as? String ?? ""
        if let questionTypeString = record["question_type"] as? String,
           let questionType = QuestionType(rawValue: questionTypeString)
        {
            question.questionType = questionType
        } else {
            question.questionType = .string
        }
        question.code = record["code"] as? String ?? ""
        question.helpText = record["help_text"] as? String ?? ""
        question.choices = record["choices"] as? [String: String]
        try await question.save(on: database)
    }

    // MARK: - Person

    static func insertPerson(
        record: [String: Any],
        lookupFields: [String],
        database: Database
    ) async throws {
        if !lookupFields.isEmpty, let email = record["email"] as? String {
            if let existing = try await Person.query(on: database)
                .filter(\.$email == email)
                .first()
            {
                existing.name = record["name"] as? String ?? existing.name
                try await existing.save(on: database)
                return
            }
        }

        let person = Person()
        person.name = record["name"] as? String ?? ""
        person.email = record["email"] as? String ?? ""
        try await person.save(on: database)
    }

    // MARK: - User

    static func insertUser(
        record: [String: Any],
        lookupFields: [String],
        database: Database
    ) async throws {
        let personId: Int32?
        if let personDict = record["person"] as? [String: Any],
           let personEmail = personDict["email"] as? String
        {
            let person = try await Person.query(on: database)
                .filter(\.$email == personEmail)
                .first()
            personId = person?.id
        } else {
            personId = nil
        }

        guard let personId = personId else {
            return
        }

        if !lookupFields.isEmpty {
            if let existing = try await User.query(on: database)
                .filter(\.$person.$id == personId)
                .first()
            {
                if let roleString = record["role"] as? String,
                   let role = UserRole(rawValue: roleString)
                {
                    existing.role = role
                }
                try await existing.save(on: database)
                return
            }
        }

        let user = User()
        user.$person.id = personId
        if let roleString = record["role"] as? String,
           let role = UserRole(rawValue: roleString)
        {
            user.role = role
        } else {
            user.role = .customer
        }
        try await user.save(on: database)
    }

    // MARK: - Entity

    static func insertEntity(
        record: [String: Any],
        lookupFields: [String],
        database: Database
    ) async throws {
        let name = record["name"] as? String ?? ""

        let entityTypeId: Int32?
        if let entityTypeDict = record["entity_type"] as? [String: Any],
           let entityTypeName = entityTypeDict["name"] as? String
        {
            if let jurisdictionDict = entityTypeDict["jurisdiction"] as? [String: Any],
               let jurisdictionName = jurisdictionDict["name"] as? String
            {
                let jurisdiction = try await Jurisdiction.query(on: database)
                    .filter(\.$name == jurisdictionName)
                    .first()

                if let jurisdictionId = jurisdiction?.id {
                    let entityType = try await EntityType.query(on: database)
                        .filter(\.$name == entityTypeName)
                        .filter(\.$jurisdiction.$id == jurisdictionId)
                        .first()
                    entityTypeId = entityType?.id
                } else {
                    entityTypeId = nil
                }
            } else {
                let entityType = try await EntityType.query(on: database)
                    .filter(\.$name == entityTypeName)
                    .first()
                entityTypeId = entityType?.id
            }
        } else if let entityTypeIdString = record["legal_entity_type_id"] as? String {
            entityTypeId = Int32(entityTypeIdString)
        } else {
            entityTypeId = nil
        }

        if !lookupFields.isEmpty, !name.isEmpty {
            if let existing = try await Entity.query(on: database)
                .filter(\.$name == name)
                .first()
            {
                if let entityTypeId = entityTypeId {
                    existing.$legalEntityType.id = entityTypeId
                }
                try await existing.save(on: database)
                return
            }
        }

        let entity = Entity()
        entity.name = name
        if let entityTypeId = entityTypeId {
            entity.$legalEntityType.id = entityTypeId
        }
        try await entity.save(on: database)
    }

    // MARK: - Credential

    static func insertCredential(
        record: [String: Any],
        lookupFields: [String],
        database: Database
    ) async throws {
        let licenseNumber = record["license_number"] as? String ?? ""

        let personId: Int32?
        if let personDict = record["person"] as? [String: Any],
           let personEmail = personDict["email"] as? String
        {
            let person = try await Person.query(on: database)
                .filter(\.$email == personEmail)
                .first()
            personId = person?.id
        } else if let personIdString = record["person_id"] as? String {
            personId = Int32(personIdString)
        } else {
            personId = nil
        }

        let jurisdictionId: Int32?
        if let jurisdictionDict = record["jurisdiction"] as? [String: Any],
           let jurisdictionName = jurisdictionDict["name"] as? String
        {
            let jurisdiction = try await Jurisdiction.query(on: database)
                .filter(\.$name == jurisdictionName)
                .first()
            jurisdictionId = jurisdiction?.id
        } else if let jurisdictionIdString = record["jurisdiction_id"] as? String {
            jurisdictionId = Int32(jurisdictionIdString)
        } else {
            jurisdictionId = nil
        }

        if !lookupFields.isEmpty, !licenseNumber.isEmpty {
            if let existing = try await Credential.query(on: database)
                .filter(\.$licenseNumber == licenseNumber)
                .first()
            {
                if let personId = personId {
                    existing.$person.id = personId
                }
                if let jurisdictionId = jurisdictionId {
                    existing.$jurisdiction.id = jurisdictionId
                }
                try await existing.save(on: database)
                return
            }
        }

        let credential = Credential()
        credential.licenseNumber = licenseNumber
        if let personId = personId {
            credential.$person.id = personId
        }
        if let jurisdictionId = jurisdictionId {
            credential.$jurisdiction.id = jurisdictionId
        }
        try await credential.save(on: database)
    }

    // MARK: - Address

    static func insertAddress(
        record: [String: Any],
        lookupFields: [String],
        database: Database
    ) async throws {
        let zip = record["zip"] as? String ?? ""
        let street = record["street"] as? String ?? ""

        if !lookupFields.isEmpty {
            var query = Address.query(on: database)

            if lookupFields.contains("zip") && !zip.isEmpty {
                query = query.filter(\.$zip == zip)
            }

            if lookupFields.contains("entity_id"),
               let entityId = try await resolveForeignKey("entity", from: record, database: database)
            {
                query = query.filter(\.$entity.$id == entityId)
            }

            if let existing = try await query.first() {
                if let entityId = try await resolveForeignKey("entity", from: record, database: database) {
                    existing.$entity.id = entityId
                }
                try await existing.save(on: database)
                return
            }
        }

        let address = Address()
        address.street = street
        address.city = record["city"] as? String ?? ""
        address.state = record["state"] as? String ?? ""
        address.zip = zip
        address.country = record["country"] as? String ?? "USA"
        address.isVerified = record["is_verified"] as? Bool ?? false

        if let entityId = try await resolveForeignKey("entity", from: record, database: database) {
            address.$entity.id = entityId
        }

        try await address.save(on: database)
    }

    // MARK: - Mailbox

    static func insertMailbox(
        record: [String: Any],
        lookupFields: [String],
        database: Database
    ) async throws {
        let mailboxNumber = record["mailbox_number"] as? Int ?? 0

        if !lookupFields.isEmpty {
            var query = Mailbox.query(on: database)

            if lookupFields.contains("mailbox_number") && mailboxNumber > 0 {
                query = query.filter(\.$mailboxNumber == mailboxNumber)
            }

            if lookupFields.contains("address_id"),
               let addressId = try await resolveForeignKey("address", from: record, database: database)
            {
                query = query.filter(\.$address.$id == addressId)
            }

            if let existing = try await query.first() {
                if let addressId = try await resolveForeignKey("address", from: record, database: database) {
                    existing.$address.id = addressId
                }
                existing.isActive = record["is_active"] as? Bool ?? existing.isActive
                try await existing.save(on: database)
                return
            }
        }

        let mailbox = Mailbox()
        mailbox.mailboxNumber = mailboxNumber
        mailbox.isActive = record["is_active"] as? Bool ?? true

        if let addressId = try await resolveForeignKey("address", from: record, database: database) {
            mailbox.$address.id = addressId
        }

        try await mailbox.save(on: database)
    }

    // MARK: - PersonEntityRole

    static func insertPersonEntityRole(
        record: [String: Any],
        lookupFields: [String],
        database: Database
    ) async throws {
        let personId: Int32?
        if let personDict = record["person"] as? [String: Any],
           let personEmail = personDict["email"] as? String
        {
            let person = try await Person.query(on: database)
                .filter(\.$email == personEmail)
                .first()
            personId = person?.id
        } else if let personIdString = record["person_id"] as? String {
            personId = Int32(personIdString)
        } else {
            personId = nil
        }

        let entityId: Int32?
        if let entityDict = record["entity"] as? [String: Any],
           let entityName = entityDict["name"] as? String
        {
            let entity = try await Entity.query(on: database)
                .filter(\.$name == entityName)
                .first()
            entityId = entity?.id
        } else if let entityIdString = record["entity_id"] as? String {
            entityId = Int32(entityIdString)
        } else {
            entityId = nil
        }

        let role = record["role"] as? String ?? "admin"

        if !lookupFields.isEmpty,
           let personId = personId,
           let entityId = entityId
        {
            let existing = try await PersonEntityRole.query(on: database)
                .filter(\.$person.$id == personId)
                .filter(\.$entity.$id == entityId)
                .filter(\.$role == PersonEntityRoleType(rawValue: role)!)
                .first()

            if existing != nil {
                return
            }
        }

        let personEntityRole = PersonEntityRole()
        if let personId = personId {
            personEntityRole.$person.id = personId
        }
        if let entityId = entityId {
            personEntityRole.$entity.id = entityId
        }
        if let roleType = PersonEntityRoleType(rawValue: role) {
            personEntityRole.role = roleType
        }
        try await personEntityRole.save(on: database)
    }

    // MARK: - Foreign Key Resolution

    static func resolveForeignKey(
        _ key: String,
        from record: [String: Any],
        database: Database
    ) async throws -> Int32? {
        let directIdKey = "\(key)_id"

        if let directId = record[directIdKey] as? Int32 {
            return directId
        }
        if let directIdString = record[directIdKey] as? String, let directId = Int32(directIdString) {
            return directId
        }

        if let nestedData = record[key] as? [String: Any] {
            switch key {
            case "entity":
                return try await findOrCreateEntity(from: nestedData, database: database)
            case "person":
                if let email = nestedData["email"] as? String {
                    let person = try await Person.query(on: database)
                        .filter(\.$email == email)
                        .first()
                    return person?.id
                }
            case "jurisdiction":
                if let name = nestedData["name"] as? String {
                    let jurisdiction = try await Jurisdiction.query(on: database)
                        .filter(\.$name == name)
                        .first()
                    return jurisdiction?.id
                }
            case "address":
                return try await findOrCreateAddress(from: nestedData, database: database)
            default:
                break
            }
        }

        return nil
    }

    static func findOrCreateEntity(
        from entityData: [String: Any],
        database: Database
    ) async throws -> Int32? {
        let name = entityData["name"] as? String ?? ""

        if let existing = try await Entity.query(on: database)
            .filter(\.$name == name)
            .first()
        {
            return existing.id
        }

        let entity = Entity()
        entity.name = name

        if let entityTypeData = entityData["entity_type"] as? [String: Any],
           let entityTypeName = entityTypeData["name"] as? String
        {

            if let jurisdictionData = entityTypeData["jurisdiction"] as? [String: Any],
               let jurisdictionName = jurisdictionData["name"] as? String
            {

                let jurisdiction = try await Jurisdiction.query(on: database)
                    .filter(\.$name == jurisdictionName)
                    .first()

                if let jurisdictionId = jurisdiction?.id {
                    let entityType = try await EntityType.query(on: database)
                        .filter(\.$name == entityTypeName)
                        .filter(\.$jurisdiction.$id == jurisdictionId)
                        .first()

                    if let entityTypeId = entityType?.id {
                        entity.$legalEntityType.id = entityTypeId
                    }
                }
            }
        }

        try await entity.save(on: database)
        return entity.id
    }

    static func findOrCreateAddress(
        from addressData: [String: Any],
        database: Database
    ) async throws -> Int32? {
        let zip = addressData["zip"] as? String ?? ""
        let street = addressData["street"] as? String ?? ""

        if let existing = try await Address.query(on: database)
            .filter(\.$zip == zip)
            .filter(\.$street == street)
            .first()
        {
            return existing.id
        }

        let address = Address()
        address.street = street
        address.city = addressData["city"] as? String ?? ""
        address.state = addressData["state"] as? String ?? ""
        address.zip = zip
        address.country = addressData["country"] as? String ?? "USA"
        address.isVerified = addressData["is_verified"] as? Bool ?? false

        if let entityId = try await resolveForeignKey("entity", from: addressData, database: database) {
            address.$entity.id = entityId
        }

        try await address.save(on: database)
        return address.id
    }
}
