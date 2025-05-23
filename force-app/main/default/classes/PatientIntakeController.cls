public with sharing class PatientIntakeController {
    
    // Create new patient intake record
    @AuraEnabled
    public static String createPatientIntake(String firstName, String lastName, Integer age, 
                                            String gender, String chiefComplaint, String complaintDetails) {
        try {
            PatientIntake__c intake = new PatientIntake__c(
                Name = firstName + ' ' + lastName,
                Age__c = age,
                Gender__c = gender,
                Complaints__c = chiefComplaint,
                ComplaintDetails__c = complaintDetails,
                IntakeTimestamp__c = Datetime.now()
            );
            
            insert intake;
            return intake.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error creating patient intake: ' + e.getMessage());
        }
    }

    // Update patient symptoms
    @AuraEnabled
    public static PatientIntake__c updateSymptoms(String intakeId, String symptoms) {
        try {
            PatientIntake__c intake = [SELECT Id, Symptoms__c FROM PatientIntake__c WHERE Id = :intakeId LIMIT 1];
            intake.Symptoms__c = symptoms;
            update intake;
            
            // Return the updated intake record
            return intake;
        } catch (Exception e) {
            throw new AuraHandledException('Error updating symptoms: ' + e.getMessage());
        }
    }

    // Update patient intake with vital signs
    @AuraEnabled
    public static void updateVitalSigns(String intakeId, String bloodPressure, Integer heartRate, 
                                      Decimal temperature, Integer oxygenSaturation, Integer respiratoryRate) {
        try {
            PatientIntake__c intake = [SELECT Id FROM PatientIntake__c WHERE Id = :intakeId LIMIT 1];
            intake.BloodPressure__c = bloodPressure;
            intake.HeartRate__c = heartRate;
            intake.Temperature__c = temperature;
            intake.OxygenSaturation__c = oxygenSaturation;
            intake.RespiratoryRate__c = respiratoryRate;
            
            update intake;
        } catch (Exception e) {
            throw new AuraHandledException('Error updating vital signs: ' + e.getMessage());
        }
    }
    
    
    // Update medical history
    @AuraEnabled
    public static void updateMedicalHistory(String intakeId, String medicalHistory) {
        try {
            PatientIntake__c intake = [SELECT Id FROM PatientIntake__c WHERE Id = :intakeId LIMIT 1];
            intake.MedicalHistory__c = medicalHistory;
            
            update intake;
        } catch (Exception e) {
            throw new AuraHandledException('Error updating medical history: ' + e.getMessage());
        }
    }
    
    // Get patient intake record
    @AuraEnabled(cacheable=true)
    public static PatientIntake__c getPatientIntake(String intakeId) {
        try {
            return [SELECT Id, Name, Age__c, Gender__c, Complaints__c, Symptoms__c,
                   BloodPressure__c, HeartRate__c, Temperature__c, OxygenSaturation__c,
                   RespiratoryRate__c, MedicalHistory__c, IntakeTimestamp__c
                   FROM PatientIntake__c WHERE Id = :intakeId LIMIT 1];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving patient intake: ' + e.getMessage());
        }
    }

    // Get all patient intake records
    @AuraEnabled(cacheable=true)
    public static List<PatientIntake__c> getAllPatientIntakes() {
        try {
            return [SELECT Id, Name, Age__c, Gender__c, Complaints__c, Symptoms__c,
                    BloodPressure__c, HeartRate__c, Temperature__c, OxygenSaturation__c,
                    RespiratoryRate__c, MedicalHistory__c, IntakeTimestamp__c
                    FROM PatientIntake__c];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving patient intakes: ' + e.getMessage());
        }
    }

}