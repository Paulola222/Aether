import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

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

    @track intakeId; // Changed from patientId to intakeId
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
            this.intakeId = result; // Save it as intakeId
            this.isLoading = true;
            this.getQuestionnaire();
        } catch (error) {
            this.showToast('Error', error.body.message, 'error');
        }
    }

    async getQuestionnaire() {
        try {
            this.isLoading = true;
            const questionnaireResponse = await getSymptomQuestionnaire({ intakeId: this.intakeId });

            console.log('Questionnaire response:', questionnaireResponse);

            if (typeof questionnaireResponse === 'string') {
                try {
                    const parsedResponse = JSON.parse(questionnaireResponse);
                    if (parsedResponse.value) {
                        this.questionnaire = this.formatQuestionnaire(parsedResponse.value);
                    } else {
                        this.questionnaire = this.formatQuestionnaire(questionnaireResponse);
                    }
                } catch (parseError) {
                    this.questionnaire = this.formatQuestionnaire(questionnaireResponse);
                }
            } else {
                this.questionnaire = this.formatQuestionnaire(questionnaireResponse);
            }

            console.log('Final formatted questionnaire:', this.questionnaire);
            this.isLoading = false;
        } catch (error) {
            this.isLoading = false;
            console.error('Error fetching questionnaire:', error);
            this.showToast('Error loading questionnaire', error.body ? error.body.message : error.message, 'error');
        }
    }

    // Helper function to format the questionnaire nicely
    formatQuestionnaire(rawText) {
        let formattedText = rawText;

        // Add <br><br> after each question number
        formattedText = formattedText.replace(/(\d+\.)/g, '<br><br><strong>$1</strong>');

        // Add <br> after each question to separate them
        formattedText = formattedText.replace(/\? /g, '?<br>');

        return formattedText;
    }


    handleSymptomsChange(event) {
        this.symptoms = event.target.value;
    }

    async handleSaveSymptoms() {
        try {
            const savedIntake = await updateSymptoms({ intakeId: this.intakeId, symptoms: this.symptoms });
            console.log('Symptoms saved successfully:', savedIntake);

            // Show success toast
            this.showToast('Success', 'Symptoms have been saved successfully!', 'success');

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
            // Save vital signs
            const savedVitals = await updateVitalSigns({
                intakeId: this.intakeId,
                bloodPressure: this.vitalSigns.bloodPressure,
                heartRate: this.vitalSigns.heartRate,
                temperature: this.vitalSigns.temperature,
                oxygenSaturation: this.vitalSigns.oxygenSaturation,
                respiratoryRate: this.vitalSigns.respiratoryRate
            });
            console.log('Vital signs saved successfully:', savedVitals);

            // Save medical history
            const savedMedicalHistory = await updateMedicalHistory({
                intakeId: this.intakeId,
                medicalHistory: this.medicalHistory
            });
            console.log('Medical history saved successfully:', savedMedicalHistory);

            // Success toast
            this.showToast('Success', 'Vital signs and medical history saved successfully!', 'success');

            // Proceed to analyze vital signs
            this.vitalsEntered = true;
            this.isAnalyzing = true;

            const result = await analyzeVitalSigns({ intakeId: this.intakeId });
            console.log('Vital signs analysis result:', result);

            if (result) {
                // Format the result for rich text display if necessary
                this.vitalAnalysis = this.formatRichTextContent(result);
            } else {
                this.vitalAnalysis = '<p>No analysis available for the provided vital signs.</p>';
            }

            this.isAnalyzing = false;
        } catch (error) {
            this.showToast('Error saving vitals or analyzing', error.body?.message || 'Unknown error occurred', 'error');
            console.error('Error during save/analyze process:', error);
            this.isAnalyzing = false;
        }
    }

    // Helper method to format content for rich text display
    formatRichTextContent(content) {
        if (!content) return '';

        // Replace newlines with HTML breaks for proper display
        let formattedContent = content.replace(/\n/g, '<br>');

        // Wrap in paragraph tag if not already wrapped in HTML
        if (!formattedContent.trim().startsWith('<')) {
            formattedContent = '<p>' + formattedContent + '</p>';
        }

        return formattedContent;
    }

    async handleCalculateESI() {
        try {
            this.isCalculating = true;
            const result = await calculateESILevel({ intakeId: this.intakeId });

            // Debug the response
            console.log('ESI calculation result:', JSON.stringify(result));

            // Make sure we have all the values
            this.esiResult = {
                ESILevel: result.ESILevel || '3',
                Rationale: result.Rationale || 'No rationale provided',
                TreatmentArea: result.TreatmentArea || 'Urgent Care',
                CriticalAlerts: result.CriticalAlerts || 'None'
            };

            this.esiCalculated = true;
            this.isCalculating = false;

            // Show success toast
            this.showToast('ESI Calculated', 'Emergency Severity Index calculation completed', 'success');
        } catch (error) {
            this.isCalculating = false;
            console.error('Error calculating ESI:', error);
            this.showToast('Error calculating ESI', error.body?.message || 'Unknown error occurred', 'error');
        }
    }

    // For conditional styling based on ESI level
    get isESILevelHigh() {
        return this.esiResult && (this.esiResult.ESILevel === '1' || this.esiResult.ESILevel === '2');
    }

    get isESILevel3() {
        return this.esiResult && this.esiResult.ESILevel === '3';
    }

    get isESILevelLow() {
        return this.esiResult && (this.esiResult.ESILevel === '4' || this.esiResult.ESILevel === '5');
    }

    async handleSaveAssessment() {
        try {
            this.isSaving = true;
            
            // Format the ESI assessment data
            const esiAssessment = {
                ESILevel: this.esiResult.ESILevel,
                Rationale: this.esiResult.Rationale,
                TreatmentArea: this.esiResult.TreatmentArea,
                CriticalAlerts: this.esiResult.CriticalAlerts
            };
            
            console.log('Saving assessment with data:', JSON.stringify(esiAssessment));
            
            // Call the Apex method to create the triage assessment
            const result = await createTriageAssessment({ 
                intakeId: this.intakeId, 
                esiAssessment: esiAssessment 
            });
            
            this.isSaving = false;
            this.assessmentId = result;
            
            // Show success message
            this.showToast('Assessment Saved', 'The triage assessment has been successfully saved.', 'success');
            
            // Fire completion event
            this.dispatchEvent(new CustomEvent('assessmentcomplete', {
                detail: {
                    assessmentId: result,
                    esiLevel: this.esiResult.ESILevel
                }
            }));
            
        } catch (error) {
            this.isSaving = false;
            console.error('Error saving assessment:', error);
            this.showToast('Error saving assessment', error.body?.message || 'An unknown error occurred', 'error');
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