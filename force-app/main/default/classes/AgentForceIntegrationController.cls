public with sharing class AgentForceIntegrationController {
    
    // Call Assessment Agent for symptom questionnaire
    @AuraEnabled
    public static String getSymptomQuestionnaire(String intakeId) {
        try {
            PatientIntake__c intake = [SELECT Id, Age__c, Gender__c, Complaints__c
                                       FROM PatientIntake__c WHERE Id = :intakeId LIMIT 1];

            Map<String, Object> params = new Map<String, Object>{
                'patientIntake.Age__c' => intake.Age__c,
                'patientIntake.Gender__c' => intake.Gender__c,
                'patientIntake.Complaints__c' => intake.Complaints__c
            };

            AgentForce.ActionRequest request = new AgentForce.ActionRequest();
            request.actionName = 'Get_Symptom_Questionnaire';
            request.parameters = params;

            AgentForce.ActionResponse response = AgentForce.invokeAction(request);
            return (String) response.output.get('Questionnaire');
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

            Map<String, Object> params = new Map<String, Object>{
                'patientIntake.Age__c' => intake.Age__c,
                'patientIntake.Gender__c' => intake.Gender__c,
                'patientIntake.BloodPressure__c' => intake.BloodPressure__c,
                'patientIntake.HeartRate__c' => intake.HeartRate__c,
                'patientIntake.Temperature__c' => intake.Temperature__c,
                'patientIntake.OxygenSaturation__c' => intake.OxygenSaturation__c,
                'patientIntake.RespiratoryRate__c' => intake.RespiratoryRate__c
            };

            AgentForce.ActionRequest request = new AgentForce.ActionRequest();
            request.actionName = 'Analyze_Vital_Signs';
            request.parameters = params;

            AgentForce.ActionResponse response = AgentForce.invokeAction(request);
            return (String) response.output.get('VitalAnalysis');
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

            Map<String, Object> params = new Map<String, Object>{
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
            request.actionName = 'Calculate_ESI_Level';
            request.parameters = params;

            AgentForce.ActionResponse response = AgentForce.invokeAction(request);

            Map<String, String> result = new Map<String, String>{
                'ESILevel' => (String) response.output.get('ESILevel'),
                'Rationale' => (String) response.output.get('Rationale'),
                'TreatmentArea' => (String) response.output.get('TreatmentArea'),
                'CriticalAlerts' => (String) response.output.get('CriticalAlerts')
            };

            return result;
        } catch (Exception e) {
            throw new AuraHandledException('Error calculating ESI level: ' + e.getMessage());
        }
    }
}
