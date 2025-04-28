public class AgentForce {
    public class ActionRequest {
        public String actionName;
        public Map<String, Object> parameters;
    }

    public class ActionResponse {
        public Map<String, Object> output;

        public ActionResponse() {
            output = new Map<String, Object>();
        }
    }

    public static ActionResponse invokeAction(ActionRequest request) {
        // Dummy implementation — replace with real logic or external service call
        ActionResponse response = new ActionResponse();
        if (request.actionName == 'Get_Symptom_Questionnaire') {
            response.output.put('Questionnaire', 'Sample questionnaire...');
        } else if (request.actionName == 'Analyze_Vital_Signs') {
            response.output.put('VitalAnalysis', 'Vitals normal.');
        } else if (request.actionName == 'Calculate_ESI_Level') {
            response.output.put('ESILevel', '2');
            response.output.put('Rationale', 'Moderate urgency based on vitals.');
            response.output.put('TreatmentArea', 'Urgent Care');
            response.output.put('CriticalAlerts', 'None');
        }
        return response;
    }
}
