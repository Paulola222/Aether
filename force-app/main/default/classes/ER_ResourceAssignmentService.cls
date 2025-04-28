public with sharing class ER_ResourceAssignmentService {
    
    @AuraEnabled(cacheable=false)
    public static void assignResource(Id patientCaseId) {
        Case patientCase = [SELECT Id, Priority, Status FROM Case WHERE Id = :patientCaseId LIMIT 1];
        
        if (patientCase.Status != 'Waiting') {
            throw new AuraHandledException('Patient is already being attended to or case is closed.');
        }
        
        // Find the available doctor/nurse with least current load
        User assignedResource = [SELECT Id, Name
                                  FROM User
                                  WHERE IsActive = true
                                  AND Profile.Name IN ('Doctor', 'Nurse')
                                  AND Id NOT IN (SELECT OwnerId FROM Case WHERE Status = 'In Progress')
                                  ORDER BY LastLoginDate DESC NULLS LAST
                                  LIMIT 1];

        if (assignedResource != null) {
            patientCase.OwnerId = assignedResource.Id;
            patientCase.Status = 'In Progress';
            update patientCase;
        } else {
            throw new AuraHandledException('No available medical staff to assign at the moment.');
        }
    }
}
