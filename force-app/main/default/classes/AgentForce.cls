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
    @TestVisible
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
        } else if (request.actionName == 'AnalyseVitalSigns') {
            return invokeVitalCheckAgent(request);
        } else if (request.actionName == 'CalcESILevel') {
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
    
                // Store the raw agent response directly under 'Questionnaire' key 
                // for simpler extraction in the controller
                response.output.put('Questionnaire', agentResponse);
                
                // Also maintain the original structure for backwards compatibility
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
            String caseId = (String)request.parameters.get('patientIntake.Id');
    
            // Create a user message
            String userMessage = 'Please retrieve the patient intake record with ID: ' + caseId + 
                                  ' and analyze the patient\'s vital signs. ' +
                                  'Identify any abnormal values, categorize the priority level (urgent, concerning, minor), ' +
                                  'and suggest appropriate monitoring recommendations.';
    
            Invocable.Action action = Invocable.Action.createCustomAction('generateAiAgentResponse', VITAL_CHECK_AGENT_NAME);
            action.setInvocationParameter('userMessage', userMessage);
            action.setInvocationParameter('CaseId', caseId);
    
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
    
                // Add to the response object - include both ways to access it
                response.output.put('Message', message);
                
                // Also include the raw response directly as VitalAnalysis
                try {
                    Map<String, Object> responseObj = (Map<String, Object>)JSON.deserializeUntyped(agentResponse);
                    if (responseObj.containsKey('value')) {
                        response.output.put('VitalAnalysis', responseObj.get('value'));
                    } else {
                        response.output.put('VitalAnalysis', agentResponse);
                    }
                } catch (Exception e) {
                    // If not JSON, just return as is
                    response.output.put('VitalAnalysis', agentResponse);
                }
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
            String caseId = (String)request.parameters.get('patientIntake.Id');
    
            // Create a user message
            String userMessage = 'Please retrieve the patient intake record with ID: ' + caseId + 
                                  ' and determine the appropriate Emergency Severity Index (ESI) level based on the patient\'s complaints, ' +
                                  'symptoms, vital signs, age, and gender. ' +
                                  'Provide the ESI level, rationale, suggested treatment area, and any critical alerts.';
    
            Invocable.Action action = Invocable.Action.createCustomAction('generateAiAgentResponse', TRIAGE_AGENT_NAME);
            action.setInvocationParameter('userMessage', userMessage);
            action.setInvocationParameter('CaseId', caseId);
    
            List<Invocable.Action.Result> results = action.invoke();
            Invocable.Action.Result result = results[0];
    
            if (result.isSuccess()) {
                String agentResponse = (String)result.getOutputParameters().get('agentResponse');
    
                // Debug the raw response
                System.debug('Raw Triage Agent Response:');
                debugJson('Triage Response Content', agentResponse);
    
                // First try to parse the outer JSON structure
                try {
                    Map<String, Object> parsedOuter = (Map<String, Object>)JSON.deserializeUntyped(agentResponse);
                    
                    // Check if we have a value field in the response
                    if (parsedOuter.containsKey('value')) {
                        String valueContent = (String)parsedOuter.get('value');
                        
                        // Default values
                        String esiLevel = '3'; 
                        String rationale = ''; 
                        String treatmentArea = 'Urgent Care';
                        String criticalAlerts = 'None';
                        
                        // Extract ESI Level using regex
                        Pattern esiPattern = Pattern.compile('ESI Level:\\s*(\\d+)');
                        Matcher esiMatcher = esiPattern.matcher(valueContent);
                        if (esiMatcher.find()) {
                            esiLevel = esiMatcher.group(1);
                        }
                        
                        // Extract Rationale - look for content between "Rationale:" and "Treatment Area:"
                        Pattern rationalePattern = Pattern.compile('(?s)Rationale:\\s*(.+?)(?=\\s*\\d+\\.\\s*Treatment Area:|Treatment Area:|$)');
                        Matcher rationaleMatcher = rationalePattern.matcher(valueContent);
                        if (rationaleMatcher.find()) {
                            rationale = rationaleMatcher.group(1).trim();
                        }
                        
                        // Extract Treatment Area
                        Pattern areaPattern = Pattern.compile('(?s)Treatment Area:\\s*(.+?)(?=\\s*\\d+\\.\\s*Critical Alerts:|Critical Alerts:|$)');
                        Matcher areaMatcher = areaPattern.matcher(valueContent);
                        if (areaMatcher.find()) {
                            treatmentArea = areaMatcher.group(1).trim();
                        }
                        
                        // Extract Critical Alerts
                        Pattern alertsPattern = Pattern.compile('(?s)Critical Alerts:\\s*(.+?)(?=\\s*\\d+\\.|$)');
                        Matcher alertsMatcher = alertsPattern.matcher(valueContent);
                        if (alertsMatcher.find()) {
                            criticalAlerts = alertsMatcher.group(1).trim();
                        }
                        
                        // Set the output values
                        response.output.put('ESILevel', esiLevel);
                        response.output.put('Rationale', rationale);
                        response.output.put('TreatmentArea', treatmentArea);
                        response.output.put('CriticalAlerts', criticalAlerts);
                        
                        // Also include the raw response for debugging
                        response.output.put('RawResponse', valueContent);
                    } else {
                        // Use direct fields if they exist
                        response.output.put('ESILevel', parsedOuter.containsKey('ESILevel') ? (String)parsedOuter.get('ESILevel') : '3');
                        response.output.put('Rationale', parsedOuter.containsKey('Rationale') ? (String)parsedOuter.get('Rationale') : 'Based on assessment');
                        response.output.put('TreatmentArea', parsedOuter.containsKey('TreatmentArea') ? (String)parsedOuter.get('TreatmentArea') : 'Urgent Care');
                        response.output.put('CriticalAlerts', parsedOuter.containsKey('CriticalAlerts') ? (String)parsedOuter.get('CriticalAlerts') : 'None');
                    }
                } catch (Exception e) {
                    System.debug('Error parsing response: ' + e.getMessage());
                    // fallback if parsing fails
                    response.output.put('ESILevel', '3');
                    response.output.put('Rationale', 'Could not parse agent response');
                    response.output.put('TreatmentArea', 'Urgent Care');
                    response.output.put('CriticalAlerts', 'None');
                    response.output.put('Error', 'Parse error: ' + e.getMessage());
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