import { LightningElement, wire, track } from 'lwc';
import getAllTriageAssessments from '@salesforce/apex/TriageAssessmentController.getAllTriageAssessments';

const COLUMNS = [
    { label: 'Patient Name', fieldName: 'patientName', type: 'text' },
    { label: 'Age', fieldName: 'patientAge', type: 'number' },
    { label: 'Gender', fieldName: 'patientGender', type: 'text' },
    { label: 'Chief Complaint', fieldName: 'chiefComplaint', type: 'text' },
    { 
        label: 'ESI Level', 
        fieldName: 'esiLevel', 
        type: 'text',
        cellAttributes: {
            class: { fieldName: 'esiLevelClass' }
        }
    },
    { label: 'Time in Queue (min)', fieldName: 'timeInQueue', type: 'number' },
    { label: 'Assigned Area', fieldName: 'assignedArea', type: 'text' },
    { label: 'Critical Alert', fieldName: 'alertDisplay', type: 'text' },
    {
        type: 'button',
        typeAttributes: {
            label: 'View Assessment',
            name: 'view_assessment',
            variant: 'brand'
        }
    }
];

export default class TriageDashboard extends LightningElement {
    @track triageList = [];
    @track selectedAssessment;
    @track error;

    columns = COLUMNS;

    @wire(getAllTriageAssessments)
    wiredAssessments({ data, error }) {
        if (data) {
            this.triageList = data.map(record => ({
                ...record,
                esiLevelClass: this.getEsiLevelClass(record.esiLevel),
                alertDisplay: record.criticalAlert ? '⚠️ ' + (record.alertDetails || 'Critical') : 'None'
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.triageList = undefined;
        }
    }

    getEsiLevelClass(esiLevel) {
        switch(esiLevel) {
            case '1': return 'slds-text-color_error'; // Red
            case '2': return 'slds-text-color_warning'; // Orange
            case '3': return 'slds-text-color_weak'; // Yellowish
            case '4': return 'slds-text-color_success'; // Green
            case '5': return 'slds-text-color_success'; // Green
            default: return '';
        }
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        if (actionName === 'view_assessment') {
            this.selectedAssessment = row;
        }
    }

    closeModal() {
        this.selectedAssessment = null;
    }
}
