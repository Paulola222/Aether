public class AgentForce {
    // Constants for agent action names
    private static final String ASSESSMENT_AGENT_NAME = 'AssessmentAgent';
    private static final String TRIAGE_AGENT_NAME = 'TriageAgent';
    private static final String VITAL_CHECK_AGENT_NAME = 'VitalCheckAgent';

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

    // Helper method to debug JSON content without truncation
    private static void debugJson(String prefix, String jsonContent) {
        try {
            Map<String, Object> parsed = (Map<String, Object>)JSON.deserializeUntyped(jsonContent);
            System.debug(prefix + ': ' + JSON.serializePretty(parsed));
        } catch(Exception e) {
            System.debug(prefix + ': Raw JSON Content: ' + jsonContent);
        }
    }

    // Main method to invoke the appropriate agent based on the action name
    public static ActionResponse invokeAction(ActionRequest request) {
        System.debug('invokeAction called with request: ' + JSON.serializePretty(request));
        if (request == null) {
            ActionResponse response = new ActionResponse();
            response.output.put('Error', 'Request was null.');
            return response;
        }
        System.debug('Action Name: ' + request.actionName);

        if (request.actionName == 'GetQuestionnaire') {
            return invokeAssessmentAgent(request);
        } else if (request.actionName == 'AnalyzeVitalSigns') {
            return invokeVitalCheckAgent(request);
        } else if (request.actionName == 'CalculateESILevel') {
            return invokeTriageAgent(request);
        } else {
            ActionResponse response = new ActionResponse();
            response.output.put('Error', 'Unknown action type: ' + request.actionName);
            return response;
        }
    }

    private static ActionResponse invokeAssessmentAgent(ActionRequest request) {
        ActionResponse response = new ActionResponse();
        try {
            String caseId = (String)request.parameters.get('patientIntake.Id');
    
            // Create a better prompt
            String userMessage = 'Please retrieve the patient intake record with ID: ' + caseId +
                                  ' and generate a complete symptom assessment questionnaire based on the patient\'s chief complaint, age, and gender. ' +
                                  'Include all relevant clinical questions organized by category to help evaluate the severity of their condition and identify any potential red flags.';
    
            Invocable.Action action = Invocable.Action.createCustomAction('generateAiAgentResponse', ASSESSMENT_AGENT_NAME);
            action.setInvocationParameter('userMessage', userMessage);
            action.setInvocationParameter('CaseId', caseId);
    
            List<Invocable.Action.Result> results = action.invoke();
            Invocable.Action.Result result = results[0];
            
            if (result.isSuccess()) {
                String agentResponse = (String)result.getOutputParameters().get('agentResponse');
                
                // Debug the raw response
                System.debug('Raw Assessment Agent Response:');
                debugJson('Assessment Response Content', agentResponse);
    
                Map<String, Object> message = new Map<String, Object>();
                message.put('id', 'unique-message-id');
                message.put('messageType', 'messageDefinition');
                message.put('staticContent', agentResponse);
                response.output.put('Message', message);
            } else {
                response.output.put('Error', 'Assessment Agent execution failed: ' + result.getErrors());
            }
        } catch (Exception e) {
            response.output.put('Error', 'Exception when invoking assessment agent: ' + e.getMessage());
        }
        return response;
    }
    

    private static ActionResponse invokeVitalCheckAgent(ActionRequest request) {
        ActionResponse response = new ActionResponse();
        try {
            Invocable.Action action = Invocable.Action.createCustomAction('generateAiAgentResponse', VITAL_CHECK_AGENT_NAME);
            action.setInvocationParameter('userMessage', 'Analyze patient vital signs');
            action.setInvocationParameter('CaseId', (String)request.parameters.get('patientIntake.Id'));
            
            List<Invocable.Action.Result> results = action.invoke();
            Invocable.Action.Result result = results[0];
            
            if (result.isSuccess()) {
                String agentResponse = (String)result.getOutputParameters().get('agentResponse');
                
                // Debug the raw response
                System.debug('Raw Vital Check Agent Response:');
                debugJson('Vital Check Response Content', agentResponse);

                Map<String, Object> message = new Map<String, Object>();
                message.put('id', 'unique-message-id');
                message.put('messageType', 'messageDefinition');
                message.put('staticContent', agentResponse);
                response.output.put('Message', message);
            } else {
                response.output.put('Error', 'Vital Check Agent execution failed: ' + result.getErrors());
            }
        } catch (Exception e) {
            response.output.put('Error', 'Exception when invoking vital check agent: ' + e.getMessage());
        }
        return response;
    }

    private static ActionResponse invokeTriageAgent(ActionRequest request) {
        ActionResponse response = new ActionResponse();
        try {
            Invocable.Action action = Invocable.Action.createCustomAction('generateAiAgentResponse', TRIAGE_AGENT_NAME);
            action.setInvocationParameter('userMessage', 'Calculate ESI level for patient triage');
            action.setInvocationParameter('CaseId', (String)request.parameters.get('patientIntake.Id'));
            
            List<Invocable.Action.Result> results = action.invoke();
            Invocable.Action.Result result = results[0];
            
            if (result.isSuccess()) {
                String agentResponse = (String)result.getOutputParameters().get('agentResponse');
                
                // Debug the raw response
                System.debug('Raw Triage Agent Response:');
                debugJson('Triage Response Content', agentResponse);

                try {
                    Map<String, Object> parsedResponse = (Map<String, Object>)JSON.deserializeUntyped(agentResponse);
                    response.output.put('ESILevel', parsedResponse.containsKey('ESILevel') ? parsedResponse.get('ESILevel') : '');
                    response.output.put('Rationale', parsedResponse.containsKey('Rationale') ? parsedResponse.get('Rationale') : '');
                    response.output.put('TreatmentArea', parsedResponse.containsKey('TreatmentArea') ? parsedResponse.get('TreatmentArea') : '');
                    response.output.put('CriticalAlerts', parsedResponse.containsKey('CriticalAlerts') ? parsedResponse.get('CriticalAlerts') : 'None');
                } catch (Exception e) {
                    response.output.put('ESILevel', '2');
                    response.output.put('Rationale', agentResponse);
                    response.output.put('TreatmentArea', 'Urgent Care');
                    response.output.put('CriticalAlerts', 'None');
                }
            } else {
                response.output.put('Error', 'Triage Agent execution failed: ' + result.getErrors());
            }
        } catch (Exception e) {
            response.output.put('Error', 'Exception when invoking triage agent: ' + e.getMessage());
        }
        return response;
    }
}