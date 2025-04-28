import { LightningElement, track } from 'lwc';
import estimateWaitTime from '@salesforce/apex/ER_WaitTimeEstimator.estimateWaitTime';

export default class WaitTimeEstimator extends LightningElement {
    @track priority;
    @track waitTime;
    priorityOptions = [
        { label: 'High', value: 'High' },
        { label: 'Medium', value: 'Medium' },
        { label: 'Low', value: 'Low' }
    ];

    handlePriorityChange(event) {
        this.priority = event.detail.value;
        this.fetchWaitTime();
    }

    fetchWaitTime() {
        estimateWaitTime({ priority: this.priority })
            .then(result => {
                this.waitTime = result;
            })
            .catch(error => {
                console.error('Error fetching wait time', error);
            });
    }
}
