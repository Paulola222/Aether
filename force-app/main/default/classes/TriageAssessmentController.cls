public with sharing class TriageAssessmentController {
    
    // Create triage assessment record from ESI calculation
    @AuraEnabled
    public static String createTriageAssessment(String patientIntakeId, String esiLevel, 
                                               String rationale, String assignedArea, 
                                               String criticalAlerts) {
        try {
            // Determine if this is a critical alert
            Boolean isCritical = false;
            if (esiLevel == '1' || esiLevel == '2') {
                isCritical = true;
            }
            
            // Calculate estimated wait time based on ESI Level (simplified logic)
            Integer waitTime = 0;
            if (esiLevel == '3') {
                waitTime = 30;
            } else if (esiLevel == '4') {
                waitTime = 60;
            } else if (esiLevel == '5') {
                waitTime = 90;
            }
            // ESI 1 and 2 get immediate attention (0 wait time)
            
            // Create the triage assessment record
            TriageAssessment__c assessment = new TriageAssessment__c(
                Name = 'Assessment for Patient ' + patientIntakeId,
                PatientIntake__c = patientIntakeId,
                ESILevel__c = esiLevel,
                Rationale__c = rationale,
                AssignedArea__c = assignedArea,
                CriticalAlert__c = isCritical,
                AlertDetails__c = criticalAlerts,
                WaitTime__c = waitTime
            );
            
            insert assessment;
            return assessment.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error creating triage assessment: ' + e.getMessage());
        }
    }
    
    // Get all triage assessments for the triage dashboard
    @AuraEnabled(cacheable=true)
    public static List<TriageAssessmentWrapper> getAllTriageAssessments() {
        try {
            List<TriageAssessmentWrapper> wrappers = new List<TriageAssessmentWrapper>();
            
            List<TriageAssessment__c> assessments = [
                SELECT Id, Name, ESILevel__c, AssignedArea__c, WaitTime__c, CriticalAlert__c,
                       AlertDetails__c, PatientIntake__c, PatientIntake__r.Name, 
                       PatientIntake__r.Age__c, PatientIntake__r.Gender__c, 
                       PatientIntake__r.Complaints__c, PatientIntake__r.IntakeTimestamp__c
                FROM TriageAssessment__c
                ORDER BY CriticalAlert__c DESC, ESILevel__c ASC, PatientIntake__r.IntakeTimestamp__c ASC
            ];
            
            for(TriageAssessment__c assessment : assessments) {
                TriageAssessmentWrapper wrapper = new TriageAssessmentWrapper();
                wrapper.id = assessment.Id;
                wrapper.patientName = assessment.PatientIntake__r.Name;
                wrapper.patientAge = Integer.valueOf(assessment.PatientIntake__r.Age__c);
                wrapper.patientGender = assessment.PatientIntake__r.Gender__c;
                wrapper.chiefComplaint = assessment.PatientIntake__r.Complaints__c;
                wrapper.esiLevel = assessment.ESILevel__c;
                wrapper.assignedArea = assessment.AssignedArea__c;
                wrapper.waitTime = Integer.valueOf(assessment.WaitTime__c);
                wrapper.intakeTime = assessment.PatientIntake__r.IntakeTimestamp__c;
                wrapper.criticalAlert = assessment.CriticalAlert__c;
                wrapper.alertDetails = assessment.AlertDetails__c;
                wrapper.patientIntakeId = assessment.PatientIntake__c;
                
                wrappers.add(wrapper);
            }
            
            return wrappers;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving triage assessments: ' + e.getMessage());
        }
    }
    
    // Wrapper class for triage assessment data
    public class TriageAssessmentWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String patientName;
        @AuraEnabled public Integer patientAge;
        @AuraEnabled public String patientGender;
        @AuraEnabled public String chiefComplaint;
        @AuraEnabled public String esiLevel;
        @AuraEnabled public String assignedArea;
        @AuraEnabled public Integer waitTime;
        @AuraEnabled public Datetime intakeTime;
        @AuraEnabled public Boolean criticalAlert;
        @AuraEnabled public String alertDetails;
        @AuraEnabled public String patientIntakeId;
    }
}