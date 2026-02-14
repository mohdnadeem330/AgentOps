import { LightningElement, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import LEAD_OBJECT from '@salesforce/schema/Lead';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class LeadForm extends LightningElement {
    leadObjectInfo;
    leadFields = [];
    isLoading = true;

    // Get Object Info to populate fields dynamically
    @wire(getObjectInfo, { objectApiName: LEAD_OBJECT })
    objectInfo({ error, data }) {
        if (data) {
            this.leadObjectInfo = data;
            // Map over the fields from the object metadata and add value to each field
            this.leadFields = Object.keys(data.fields).map(fieldName => {
                const field = data.fields[fieldName];
                // Default value for lead data or empty string if not provided
                let picklistOptions = [];
                if (field.picklistValues) {
                    console.log('picklist exists');
                    // Extracting picklist options
                    picklistOptions = field.picklistValues.map(option => ({
                        label: option.label,
                        value: option.value
                    }));
                }
                return {
                    label: field.label,
                    name: fieldName,
                    type: field.type,
                    required: field.required,
                    value: '', // Initialize the value for the field
                    options: picklistOptions, // Add picklist options if they exist
                    hasPicklist: picklistOptions.length > 0, // Check if picklist options exist
                    hasDependencies: field.dependencies && field.dependencies.length > 0
                };
            });
            this.isLoading = false;
        } else if (error) {
            console.error('Error fetching object info', error);
        }
    }

    handleChange(event) {
        const fieldName = event.target.name;
        const value = event.target.value;
        // Find the field in leadFields and update the value
        const field = this.leadFields.find(f => f.name === fieldName);
        if (field) {
            field.value = value; // Update the value directly in the leadFields
        }
    }

    handleSubmit() {
        const requiredFields = this.leadFields.filter(field => field.required);
        let allValid = true;

        requiredFields.forEach(field => {
            const inputElement = this.template.querySelector(`[data-id="${field.name}"]`);
            if (!inputElement.checkValidity()) {
                inputElement.reportValidity();
                allValid = false;
            }
        });

        if (allValid) {
            // Handle Lead creation logic
            this.showSuccessToast();
        } else {
            this.showErrorToast();
        }
    }

    showSuccessToast() {
        const event = new ShowToastEvent({
            title: 'Lead Created',
            message: 'The lead was successfully created.',
            variant: 'success',
        });
        this.dispatchEvent(event);
    }

    showErrorToast() {
        const event = new ShowToastEvent({
            title: 'Error',
            message: 'Please fill in all required fields.',
            variant: 'error',
        });
        this.dispatchEvent(event);
    }

    // New method to return input type based on the field type
    getInputType(fieldType) {
        return fieldType === 'email' ? 'email' : 'text';
    }
}