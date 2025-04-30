public with sharing class AgentForceIntegrationController {

    @AuraEnabled(cacheable=true)
    public static String getSymptomQuestionnaire(String intakeId) {
        try {
            System.debug('Looking for PatientIntake__c with Id: ' + intakeId);

            List<PatientIntake__c> intakeList = [
                SELECT Id, Age__c, Gender__c, Complaints__c
                FROM PatientIntake__c
                WHERE Id = :intakeId
                LIMIT 1
            ];

            if (intakeList.isEmpty()) {
                throw new AuraHandledException('Patient intake record not found for ID: ' + intakeId);
            }

            PatientIntake__c intake = intakeList[0];

            // Adding intakeId to parameters
            Map<String, Object> params = new Map<String, Object>{
                'patientIntake.Id' => intake.Id,  // Adding record ID to params
                'patientIntake.Age__c' => intake.Age__c,
                'patientIntake.Gender__c' => intake.Gender__c,
                'patientIntake.Complaints__c' => intake.Complaints__c
            };

            AgentForce.ActionRequest request = new AgentForce.ActionRequest();
            request.actionName = 'GetQuestionnaire';
            request.parameters = params;

            AgentForce.ActionResponse response = AgentForce.invokeAction(request);
            
            // Extract the questionnaire content from the response
            if (response.output.containsKey('Message')) {
                Map<String, Object> message = (Map<String, Object>)response.output.get('Message');
                if (message != null && message.containsKey('staticContent')) {
                    // Parse the staticContent which might be a JSON string
                    Object content = message.get('staticContent');
                    if (content instanceof String) {
                        try {
                            Map<String, Object> contentMap = (Map<String, Object>)JSON.deserializeUntyped((String)content);
                            if (contentMap.containsKey('value')) {
                                return (String)contentMap.get('value');
                            }
                            return (String)content;
                        } catch (Exception e) {
                            // If it's not valid JSON, return it as is
                            return (String)content;
                        }
                    }
                }
            }
            
            // If we couldn't find the questionnaire content
            throw new AuraHandledException('Could not find questionnaire content in the response');
        } catch (Exception e) {
            throw new AuraHandledException('Error getting symptom questionnaire: ' + e.getMessage());
        }
    }

    // Call Vital Check Agent for vital signs analysis
    @AuraEnabled
    public static String analyzeVitalSigns(String intakeId) {
        try {
            PatientIntake__c intake = [SELECT Id, Age__c, Gender__c, BloodPressure__c, HeartRate__c,
                                    Temperature__c, OxygenSaturation__c, RespiratoryRate__c
                                    FROM PatientIntake__c WHERE Id = :intakeId LIMIT 1];

            // Adding intakeId to parameters
            Map<String, Object> params = new Map<String, Object>{
                'patientIntake.Id' => intake.Id,  // Adding record ID to params
                'patientIntake.Age__c' => intake.Age__c,
                'patientIntake.Gender__c' => intake.Gender__c,
                'patientIntake.BloodPressure__c' => intake.BloodPressure__c,
                'patientIntake.HeartRate__c' => intake.HeartRate__c,
                'patientIntake.Temperature__c' => intake.Temperature__c,
                'patientIntake.OxygenSaturation__c' => intake.OxygenSaturation__c,
                'patientIntake.RespiratoryRate__c' => intake.RespiratoryRate__c
            };

            AgentForce.ActionRequest request = new AgentForce.ActionRequest();
            request.actionName = 'AnalyseVitalSigns';
            request.parameters = params;

            AgentForce.ActionResponse response = AgentForce.invokeAction(request);
            
            // Debug the response
            System.debug('Full response output: ' + JSON.serializePretty(response.output));
            
            // Check if Message exists in the response
            if (response.output.containsKey('Message')) {
                Map<String, Object> message = (Map<String, Object>)response.output.get('Message');
                if (message != null && message.containsKey('staticContent')) {
                    String staticContent = (String)message.get('staticContent');
                    
                    try {
                        // Try to parse as JSON first
                        Map<String, Object> contentMap = (Map<String, Object>)JSON.deserializeUntyped(staticContent);
                        if (contentMap.containsKey('value')) {
                            return (String)contentMap.get('value');
                        }
                        return staticContent;
                    } catch(Exception e) {
                        // If not valid JSON, return as is
                        return staticContent;
                    }
                }
            }
            
            // Fallback to original approach
            if (response.output.containsKey('VitalAnalysis')) {
                return (String) response.output.get('VitalAnalysis');
            }
            
            return null;
        } catch (Exception e) {
            throw new AuraHandledException('Error analyzing vital signs: ' + e.getMessage());
        }
    }
    
    // Call Triage Agent for ESI calculation
    @AuraEnabled
    public static Map<String, String> calculateESILevel(String intakeId) {
        try {
            PatientIntake__c intake = [SELECT Id, Age__c, Gender__c, Complaints__c, Symptoms__c,
                                    BloodPressure__c, HeartRate__c, Temperature__c, OxygenSaturation__c,
                                    RespiratoryRate__c, MedicalHistory__c
                                    FROM PatientIntake__c WHERE Id = :intakeId LIMIT 1];

            // Adding intakeId to parameters
            Map<String, Object> params = new Map<String, Object>{
                'patientIntake.Id' => intake.Id,  // Adding record ID to params
                'patientIntake.Age__c' => intake.Age__c,
                'patientIntake.Gender__c' => intake.Gender__c,
                'patientIntake.Complaints__c' => intake.Complaints__c,
                'patientIntake.Symptoms__c' => intake.Symptoms__c,
                'patientIntake.BloodPressure__c' => intake.BloodPressure__c,
                'patientIntake.HeartRate__c' => intake.HeartRate__c,
                'patientIntake.Temperature__c' => intake.Temperature__c,
                'patientIntake.OxygenSaturation__c' => intake.OxygenSaturation__c,
                'patientIntake.RespiratoryRate__c' => intake.RespiratoryRate__c,
                'patientIntake.MedicalHistory__c' => intake.MedicalHistory__c
            };

            AgentForce.ActionRequest request = new AgentForce.ActionRequest();
            request.actionName = 'CalcESILevel';
            request.parameters = params;

            AgentForce.ActionResponse response = AgentForce.invokeAction(request);
            
            // Debug the full response
            System.debug('Full ESI Calculation Response: ' + JSON.serializePretty(response.output));

            // Check if we have expected keys in the response
            Map<String, String> result = new Map<String, String>();
            
            // Get ESI Level with fallback
            if (response.output.containsKey('ESILevel')) {
                result.put('ESILevel', String.valueOf(response.output.get('ESILevel')));
            } else {
                result.put('ESILevel', '3'); // Default to level 3
            }
            
            // Get Rationale with fallback
            if (response.output.containsKey('Rationale') && String.isNotBlank(String.valueOf(response.output.get('Rationale')))) {
                result.put('Rationale', String.valueOf(response.output.get('Rationale')));
            } else if (response.output.containsKey('RawResponse')) {
                result.put('Rationale', String.valueOf(response.output.get('RawResponse')));
            } else {
                result.put('Rationale', 'No rationale provided');
            }
            
            // Get Treatment Area with fallback
            if (response.output.containsKey('TreatmentArea') && String.isNotBlank(String.valueOf(response.output.get('TreatmentArea')))) {
                result.put('TreatmentArea', String.valueOf(response.output.get('TreatmentArea')));
            } else {
                result.put('TreatmentArea', 'Urgent Care'); // Default
            }
            
            // Get Critical Alerts with fallback
            if (response.output.containsKey('CriticalAlerts') && String.isNotBlank(String.valueOf(response.output.get('CriticalAlerts')))) {
                result.put('CriticalAlerts', String.valueOf(response.output.get('CriticalAlerts')));
            } else {
                result.put('CriticalAlerts', 'None'); // Default
            }

            // Add debug info
            System.debug('Returning ESI results: ' + JSON.serializePretty(result));
            return result;
        } catch (Exception e) {
            System.debug('Error in calculateESILevel: ' + e.getMessage() + '\n' + e.getStackTraceString());
            throw new AuraHandledException('Error calculating ESI level: ' + e.getMessage());
        }
    }
}