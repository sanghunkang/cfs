import KituraContracts
import MongoKitten
import LoggerAPI
import Foundation

func getCurrentDateString() -> String {
    let now = Date()
    let formatter = DateFormatter()
    formatter.timeZone = TimeZone.current
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let dateString = formatter.string(from: now)
    return dateString
}

func initializeContentForwardRoutes(app: App) {
    app.router.get("/getContent", handler: app.getContentHandler)
    app.router.post("/insertContent", handler: app.insertContentHandler)
    app.router.post("/updateContent", handler: app.updateContentHandler)
    // app.router.put("/updateContentRank", handler: app.updateContentRankHandler)
}

extension App {
    // static let database = try! Database.synchronousConnect("mongodb://mongodb:27017/adaptive_cram")
    static let database = try! Database.synchronousConnect("mongodb://mongo:27017/adaptive_cram")
    // static let database = try! Database.synchronousConnect("mongodb://localhost/adaptive_cram")
    static var codableStoreBookDocument = [BookDocument]()

    func getContentHandler(completion: @escaping (Content?, RequestError?) -> Void) {
        print("mongodb://mongoow:27017/adaptive_cram")

        // Check if collections exist
        let collection = App.database["contents"]

        // Algorithm
        do {
            // Sample from latest error set (Top N)
            let contents = try collection
                .find([
                    "set_name": "commercial_law"
                ])
                // .find()
                .sort([
                    "last_succeeded_at": .ascending,
                    "last_failed_at" : .descending,
                    "created_at": .descending,
                ])
                .decode(Content.self)
                .getAllResults()
                .wait() 
            print(contents)

            // Sample from the rest
            // let contentsNormal = try collection.find({"latest error": {"$lt": "....", "max": 100}})
            //         .decode(BookDocument.self)
            //         .getAllResults()
            //         .wait() 
            // // Concatenate two sets
            // let contentsCandidates = contentsWrong + contentsNormal 
            // // Random selection from Dirichlet distribution with rank as alphas
            // if contents.count == 0 {
            //     throw error
            // } else {
                let content = contents[0]
            // }
            // content = Dirichlet(contentsCandidates)

            // Send respoese
            completion(content, nil)
        } catch let error {
            Log.error(error.localizedDescription)
            return completion(nil, .internalServerError)
        }
    }

    // Insert content defined by user into database
    func insertContentHandler(content: Content, completion: @escaping (Document?, RequestError?) -> Void) {
        // Check if collections exist
        let collection = App.database["contents"]
        
        // Insert Document
        do {
            var content = content
            content.created_at = getCurrentDateString()
            content.count_succeeded = 0
            content.count_failed = 0
            content.count_gaveup = 0

            let document: Document = try BSONEncoder().encode(content)
            print(document)
            collection.insert(document)
            completion(document, nil)
        } catch let error {
            Log.error(error.localizedDescription)
            return completion(nil, .internalServerError)
        }
    }

    // Update content itself
    func updateContentHandler(content: Content, completion: @escaping (Document?, RequestError?) -> Void) {
        // After all, only relevant ones are:
        // 1. setname, 
        // 2. has succeeded/failed/gaveup, 
        // 3. id of content‘
                
        // Check if collections exist
        let collection = App.database["contents"]

        do {
            let document: Document = try BSONEncoder().encode(content)

            let objectId = try ObjectId(content._id!)
            var updateSetting: [String: Primitive?] = [:]
            
            updateSetting["last_served_at"] = getCurrentDateString()

            // TO CHANGE WHEN PARAMETER CHANGES
            if content.last_failed_at != nil {
                updateSetting["last_failed_at"] = getCurrentDateString()
                updateSetting["count_failed"] = (content.count_failed ?? 0) + 1
            } else if content.last_succeeded_at != nil {
                updateSetting["last_succeeded_at"] = getCurrentDateString()
                updateSetting["count_succeeded"] = (content.count_succeeded ?? 0) + 1
            } else {
                updateSetting["last_gaveup_at"] = getCurrentDateString()
                updateSetting["count_gaveup"] = (content.count_gaveup ?? 0) + 1
            }

            // update document
            let result = try collection.update(
                where: "_id" == objectId, 
                setting: updateSetting
            ).wait()

            print(result)
            // RETURN TYPE WILL BE CHANGED TO MEET HTTP REQUEST-RESPONSE SPEC
            completion(document, nil)
        } catch let error {
            Log.error(error.localizedDescription)
            return completion(nil, .internalServerError)
        }
    }
}