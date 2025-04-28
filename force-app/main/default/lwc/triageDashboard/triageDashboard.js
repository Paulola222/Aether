import { LightningElement, wire, track } from 'lwc';
import getWaitingPatients from '@salesforce/apex/ER_TriageService.getWaitingPatients';
import assignResource from '@salesforce/apex/ER_ResourceAssignmentService.assignResource';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

const columns = [
    { label: 'Patient Name', fieldName: 'ContactName' },
    { label: 'Priority', fieldName: 'Priority' },
    { label: 'Arrival Time', fieldName: 'CreatedDate', type: 'date' },
    {
        type: 'button',
        typeAttributes: {
            label: 'Assign Resource',
            name: 'assign',
            title: 'Assign',
            variant: 'brand',
            iconPosition: 'left'
        }
    }
];

export default class TriageDashboard extends LightningElement {
    @track patients;
    @track error;
    columns = columns;
    wiredResult;

    @wire(getWaitingPatients)
    wiredPatients(value) {
        this.wiredResult = value;
        const { data, error } = value;
        if (data) {
            this.patients = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.patients = undefined;
        }
    }

    refreshQueue() {
        refreshApex(this.wiredResult);
    }

    async handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'assign') {
            try {
                await assignResource({ patientCaseId: row.Id });
                this.showToast('Success', 'Resource Assigned Successfully!', 'success');
                this.refreshQueue();
            } catch (error) {
                this.showToast('Error', error.body.message, 'error');
            }
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        }));
    }

    // Coloring rows based on Priority
    rowClass(data) {
        if (data.Priority === 'High') {
            return 'high-priority';
        } else if (data.Priority === 'Medium') {
            return 'medium-priority';
        } else if (data.Priority === 'Low') {
            return 'low-priority';
        }
        return '';
    }

    connectedCallback() {
        // Auto-refresh every 1 minute
        setInterval(() => {
            this.refreshQueue();
        }, 60000); // 60000 ms = 60 seconds
    }
}
