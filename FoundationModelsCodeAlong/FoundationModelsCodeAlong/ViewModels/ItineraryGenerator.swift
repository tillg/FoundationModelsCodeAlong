import Foundation
import FoundationModels
import Observation

@Observable
@MainActor
final class ItineraryGenerator {
    
    var error: Error?
    let landmark: Landmark
    
    private var session: LanguageModelSession
    
    private(set) var itinerary: Itinerary.PartiallyGenerated?
    
    init(landmark: Landmark) {
        self.landmark = landmark
        
        let pointOfInterestTool = FindPointsOfInterestTool(landmark: landmark)
        let instructions = Instructions {
            "Your job is to create an itinerary for the user."
            "Each day needs an activity, hotel and restaurant."
            """
            Always use the findPointsOfInterest tool to find businesses
            and activities in \(landmark.name), especially hotels and restaurants.
            
            The point of interest categories may include hotel and restaurant.
            """
            landmark.description
        }
        
        self.session = LanguageModelSession(tools: [pointOfInterestTool],
                                            instructions: instructions)

    }

    func generateItinerary(dayCount: Int = 3) async {
        do {
            let prompt = Prompt {
                "Generate a \(dayCount)-day itinerary to \(landmark.name)."
                "Here is an example of the desired format, but don't copy its content:"
                Itinerary.exampleTripToJapan
            }
            let stream = session.streamResponse(to: prompt,
                                                generating: Itinerary.self,
                                                includeSchemaInPrompt: false)
            for try await partialResponse in stream {
                self.itinerary = partialResponse.content
            }

        } catch {
            self.error = error
        }
    }

    func prewarmModel() {
        session.prewarm()
    }
}
