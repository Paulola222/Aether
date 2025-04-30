import { LightningElement, wire } from 'lwc';
import getAllPatientIntakes from '@salesforce/apex/PatientIntakeController.getAllPatientIntakes';

const columns = [
    { label: 'Patient Name', fieldName: 'Name' },
    { label: 'Age', fieldName: 'Age__c' },
    { label: 'Gender', fieldName: 'Gender__c' },
    { label: 'Chief Complaint', fieldName: 'Complaints__c' },
    { label: 'Intake Date', fieldName: 'IntakeTimestamp__c', type: 'date' }
];

export default class PatientIntakeList extends LightningElement {
    patientRecords = [];
    columns = columns;

    @wire(getAllPatientIntakes)
    wiredPatientIntakes({ error, data }) {
        if (data) {
            this.patientRecords = data;
        } else if (error) {
            // Handle error
            console.error('Error retrieving patient intake records:', error);
        }
    }
}
