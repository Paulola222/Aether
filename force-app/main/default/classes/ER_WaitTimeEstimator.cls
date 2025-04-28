public with sharing class ER_WaitTimeEstimator {
    
    @AuraEnabled(cacheable=true)
    public static Integer estimateWaitTime(String priority) {
        // Count the number of waiting cases
        Integer waitingCases = [SELECT count() FROM Case WHERE Status = 'Waiting' AND Priority = :priority];
        
        if (waitingCases > 0) {
            // Assume every patient takes approx 10 minutes of triage time
            return 10 * waitingCases;
        } else {
            return 5; // Default minimal wait
        }
    }
}
