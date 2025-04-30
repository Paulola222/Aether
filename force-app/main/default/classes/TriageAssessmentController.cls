public with sharing class TriageAssessmentController {
    
    @AuraEnabled
    public static String createTriageAssessment(String intakeId, Map<String, Object> esiAssessment) {
        try {
            // Extract values from the ESI assessment map
            String esiLevel = (String)esiAssessment.get('ESILevel');
            String rationale = (String)esiAssessment.get('Rationale');
            String assignedArea = (String)esiAssessment.get('TreatmentArea');
            String criticalAlerts = (String)esiAssessment.get('CriticalAlerts');
            
            // Log the received data for debugging
            System.debug('Creating triage assessment with: ');
            System.debug('IntakeId: ' + intakeId);
            System.debug('ESI Level: ' + esiLevel);
            System.debug('Treatment Area: ' + assignedArea);
            System.debug('Critical Alerts: ' + criticalAlerts);
            
            // Ensure we have valid data
            if (String.isBlank(intakeId)) {
                throw new AuraHandledException('Patient Intake ID is required');
            }
            
            if (String.isBlank(esiLevel)) {
                esiLevel = '3'; // Default to level 3 if not provided
            }
            
            if (String.isBlank(assignedArea)) {
                assignedArea = 'Urgent Care'; // Default treatment area
            }
            
            if (String.isBlank(criticalAlerts)) {
                criticalAlerts = 'None'; // Default critical alerts
            }
            
            // Get patient name for the assessment record name
            String patientName = 'Unknown';
            try {
                PatientIntake__c intake = [SELECT Name FROM PatientIntake__c WHERE Id = :intakeId LIMIT 1];
                patientName = intake.Name;
            } catch (Exception e) {
                // Continue with default patient name
                System.debug('Could not retrieve patient name: ' + e.getMessage());
            }
            
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
                Name = 'Assessment for ' + patientName,
                PatientIntake__c = intakeId,
                ESILevel__c = esiLevel,
                Rationale__c = truncateIfNeeded(rationale, 32768), // Handle potential long text field limitations
                AssignedArea__c = assignedArea,
                CriticalAlert__c = isCritical,
                AlertDetails__c = truncateIfNeeded(criticalAlerts, 255),
                WaitTime__c = waitTime
            );
            
            // Insert with sharing rules enforced
            insert assessment;
            
            // Log success
            System.debug('Created triage assessment with ID: ' + assessment.Id);
            return assessment.Id;
        } catch (Exception e) {
            System.debug('Error creating triage assessment: ' + e.getMessage() + '\n' + e.getStackTraceString());
            throw new AuraHandledException('Error creating triage assessment: ' + e.getMessage());
        }
    }
    
   
    private static String truncateIfNeeded(String input, Integer maxLength) {
        if (String.isBlank(input)) {
            return '';
        }
        
        if (input.length() > maxLength) {
            return input.substring(0, maxLength - 3) + '...';
        }
        
        return input;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<TriageAssessmentWrapper> getAllTriageAssessments() {
        try {
            List<TriageAssessmentWrapper> wrappers = new List<TriageAssessmentWrapper>();
            
            // Query triage assessments with related patient intake data
            // Sort by critical status, ESI level, and intake timestamp
            List<TriageAssessment__c> assessments = [
                SELECT Id, Name, ESILevel__c, AssignedArea__c, WaitTime__c, CriticalAlert__c,
                       AlertDetails__c, Rationale__c, CreatedDate, PatientIntake__c, 
                       PatientIntake__r.Name, PatientIntake__r.Age__c, PatientIntake__r.Gender__c, 
                       PatientIntake__r.Complaints__c, PatientIntake__r.IntakeTimestamp__c,
                       PatientIntake__r.BloodPressure__c, PatientIntake__r.HeartRate__c,
                       PatientIntake__r.Temperature__c, PatientIntake__r.OxygenSaturation__c
                FROM TriageAssessment__c
                ORDER BY CriticalAlert__c DESC, ESILevel__c ASC, PatientIntake__r.IntakeTimestamp__c ASC
            ];
            
            // Process each assessment into a wrapper object
            for(TriageAssessment__c assessment : assessments) {
                TriageAssessmentWrapper wrapper = new TriageAssessmentWrapper();
                wrapper.id = assessment.Id;
                wrapper.patientName = assessment.PatientIntake__r.Name;
                wrapper.patientAge = assessment.PatientIntake__r.Age__c != null ? 
                                    Integer.valueOf(assessment.PatientIntake__r.Age__c) : 0;
                wrapper.patientGender = assessment.PatientIntake__r.Gender__c;
                wrapper.chiefComplaint = assessment.PatientIntake__r.Complaints__c;
                wrapper.esiLevel = assessment.ESILevel__c;
                wrapper.assignedArea = assessment.AssignedArea__c;
                wrapper.waitTime = assessment.WaitTime__c != null ? 
                                   Integer.valueOf(assessment.WaitTime__c) : 0;
                wrapper.intakeTime = assessment.PatientIntake__r.IntakeTimestamp__c;
                wrapper.criticalAlert = assessment.CriticalAlert__c;
                wrapper.alertDetails = assessment.AlertDetails__c;
                wrapper.patientIntakeId = assessment.PatientIntake__c;
                wrapper.rationale = assessment.Rationale__c;
                wrapper.createdDate = assessment.CreatedDate;
                
                // Add vital signs
                wrapper.bloodPressure = assessment.PatientIntake__r.BloodPressure__c;
                wrapper.heartRate = assessment.PatientIntake__r.HeartRate__c;
                wrapper.temperature = assessment.PatientIntake__r.Temperature__c;
                wrapper.oxygenSaturation = assessment.PatientIntake__r.OxygenSaturation__c;
                
                // Calculate time in queue (minutes from intake time to now)
                if (assessment.PatientIntake__r.IntakeTimestamp__c != null) {
                    Long timeInQueueMillis = System.now().getTime() - assessment.PatientIntake__r.IntakeTimestamp__c.getTime();
                    wrapper.timeInQueue = Integer.valueOf(timeInQueueMillis / (1000 * 60)); // Convert to minutes
                } else {
                    wrapper.timeInQueue = 0;
                }
                
                wrappers.add(wrapper);
            }
            
            return wrappers;
        } catch (Exception e) {
            System.debug('Error retrieving triage assessments: ' + e.getMessage() + '\n' + e.getStackTraceString());
            throw new AuraHandledException('Error retrieving triage assessments: ' + e.getMessage());
        }
    }
    
    public class TriageAssessmentWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String patientName;
        @AuraEnabled public Integer patientAge;
        @AuraEnabled public String patientGender;
        @AuraEnabled public String chiefComplaint;
        @AuraEnabled public String esiLevel;
        @AuraEnabled public String assignedArea;
        @AuraEnabled public Integer waitTime;
        @AuraEnabled public Integer timeInQueue;
        @AuraEnabled public Datetime intakeTime;
        @AuraEnabled public Datetime createdDate;
        @AuraEnabled public Boolean criticalAlert;
        @AuraEnabled public String alertDetails;
        @AuraEnabled public String patientIntakeId;
        @AuraEnabled public String rationale;
        
        // Vital signs
        @AuraEnabled public String bloodPressure;
        @AuraEnabled public Decimal heartRate;
        @AuraEnabled public Decimal temperature;
        @AuraEnabled public Decimal oxygenSaturation;
    }
}