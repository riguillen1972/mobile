import SwiftUI

struct ToolContainerView: View {
    @Environment(\.presentationMode) var presentationMode
    let tool: StudyTool
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.theme.mainBackground.ignoresSafeArea()
                
                VStack {
                    switch tool {
                    case .examOracle:
                        ExamOracleView()
                    case .knowledgeGap:
                        KnowledgeGapView()
                    case .mvPlanner:
                        MVPlannerView()
                    case .smartSummarizer:
                        SmartSummarizerView()
                    case .spacedRep:
                        SpacedRepView()
                    case .conceptStoryteller:
                        ConceptStorytellerView()
                    case .debateMode:
                        DebateModeView()
                    case .curiosityRabbitHole:
                        CuriosityRabbitHoleView()
                    case .personalityTutor:
                        PersonalityTutorView()
                    case .makeItClick:
                        MakeItClickView()
                    case .studyStreaks:
                        StudyStreaksView()
                    case .feynmanMode:
                        FeynmanModeView()
                    case .deepUnderstanding:
                        DeepUnderstandingView()
                    case .mentalModel:
                        MentalModelView()
                    case .essayBrutalist:
                        EssayBrutalistView()
                    case .crossSubject:
                        CrossSubjectView()
                    case .metacognition:
                        MetacognitionView()
                    case .professorMode:
                        ProfessorModeView()

                    }
                }
            }
            .navigationTitle(tool.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
