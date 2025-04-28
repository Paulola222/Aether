import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import createPatientIntake from '@salesforce/apex/PatientIntakeController.createPatientIntake';
import updateSymptoms from '@salesforce/apex/PatientIntakeController.updateSymptoms';
import updateVitalSigns from '@salesforce/apex/PatientIntakeController.updateVitalSigns';
import updateMedicalHistory from '@salesforce/apex/PatientIntakeController.updateMedicalHistory';

import getSymptomQuestionnaire from '@salesforce/apex/AgentForceIntegrationController.getSymptomQuestionnaire';
import analyzeVitalSigns from '@salesforce/apex/AgentForceIntegrationController.analyzeVitalSigns';
import calculateESILevel from '@salesforce/apex/AgentForceIntegrationController.calculateESILevel';

import createTriageAssessment from '@salesforce/apex/TriageAssessmentController.createTriageAssessment';

export default class PatientIntakeForm extends LightningElement {
    @track firstName = '';
    @track lastName = '';
    @track age;
    @track gender = '';
    @track complaint = '';
    @track complaintDetails = '';
    @track genderOptions = [
        { label: 'Male', value: 'Male' },
        { label: 'Female', value: 'Female' },
        { label: 'Other', value: 'Other' }
    ];
    @track complaintOptions = [
        { label: 'Chest Pain', value: 'Chest Pain' },
        { label: 'Shortness of Breath', value: 'Shortness of Breath' },
        { label: 'Abdominal Pain', value: 'Abdominal Pain' },
        { label: 'Other', value: 'Other' }
    ];

    @track patientId;
    @track questionnaire;
    @track symptoms;
    @track isLoading = false;
    @track isAnalyzing = false;
    @track vitalSigns = {
        bloodPressure: '',
        heartRate: '',
        temperature: '',
        oxygenSaturation: '',
        respiratoryRate: ''
    };
    @track medicalHistory = '';
    @track vitalsEntered = false;
    @track vitalAnalysis;
    @track esiResult;
    @track esiCalculated = false;
    @track isCalculating = false;
    @track showSuccessToast = false;

    handleFirstNameChange(event) {
        this.firstName = event.target.value;
    }
    handleLastNameChange(event) {
        this.lastName = event.target.value;
    }
    handleAgeChange(event) {
        this.age = event.target.value;
    }
    handleGenderChange(event) {
        this.gender = event.detail.value;
    }
    handleComplaintChange(event) {
        this.complaint = event.detail.value;
    }
    handleComplaintDetailsChange(event) {
        this.complaintDetails = event.target.value;
    }

    async handleSubmit() {
        try {
            const result = await createPatientIntake({
                firstName: this.firstName,
                lastName: this.lastName,
                age: this.age,
                gender: this.gender,
                chiefComplaint: this.complaint,
                complaintDetails: this.complaintDetails
            });
            this.patientId = result;
            this.isLoading = true;
            this.getQuestionnaire();
        } catch (error) {
            this.showToast('Error', error.body.message, 'error');
        }
    }

    async getQuestionnaire() {
        try {
            const questions = await getSymptomQuestionnaire({ patientId: this.patientId });
            this.questionnaire = questions;
            this.isLoading = false;
        } catch (error) {
            this.showToast('Error loading questionnaire', error.body.message, 'error');
        }
    }

    handleSymptomsChange(event) {
        this.symptoms = event.target.value;
    }

    async handleSaveSymptoms() {
        try {
            await updateSymptoms({ patientId: this.patientId, symptoms: this.symptoms });
        } catch (error) {
            this.showToast('Error saving symptoms', error.body.message, 'error');
        }
    }

    handleBloodPressureChange(event) {
        this.vitalSigns.bloodPressure = event.target.value;
    }
    handleHeartRateChange(event) {
        this.vitalSigns.heartRate = event.target.value;
    }
    handleTemperatureChange(event) {
        this.vitalSigns.temperature = event.target.value;
    }
    handleOxygenSaturationChange(event) {
        this.vitalSigns.oxygenSaturation = event.target.value;
    }
    handleRespiratoryRateChange(event) {
        this.vitalSigns.respiratoryRate = event.target.value;
    }
    handleMedicalHistoryChange(event) {
        this.medicalHistory = event.target.value;
    }

    async handleSaveVitals() {
        try {
            await updateVitalSigns({ patientId: this.patientId, vitalSigns: this.vitalSigns });
            await updateMedicalHistory({ patientId: this.patientId, medicalHistory: this.medicalHistory });
            this.vitalsEntered = true;
            this.isAnalyzing = true;
            const result = await analyzeVitalSigns({ patientId: this.patientId });
            this.vitalAnalysis = result;
            this.isAnalyzing = false;
        } catch (error) {
            this.showToast('Error saving vitals or analyzing', error.body.message, 'error');
        }
    }

    async handleCalculateESI() {
        try {
            this.isCalculating = true;
            const result = await calculateESILevel({ patientId: this.patientId });
            this.esiResult = result;
            this.esiCalculated = true;
            this.isCalculating = false;
        } catch (error) {
            this.showToast('Error calculating ESI', error.body.message, 'error');
        }
    }

    async handleSaveAssessment() {
        try {
            await createTriageAssessment({ patientId: this.patientId, esiAssessment: this.esiResult });
            this.showSuccessToast = true;
        } catch (error) {
            this.showToast('Error saving assessment', error.body.message, 'error');
        }
    }

    closeSuccessToast() {
        this.showSuccessToast = false;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant
        }));
    }
}