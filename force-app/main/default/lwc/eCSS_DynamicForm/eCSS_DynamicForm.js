import { LightningElement,api,wire,track } from 'lwc';
import getFieldSetFields from '@salesforce/apex/ECSS_FieldsMetadataHelper.getFieldSetFields';
import getRecordData from '@salesforce/apex/ECSS_FieldsMetadataHelper.getRecordData';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { FlowNavigationNextEvent, FlowNavigationFinishEvent } from "lightning/flowSupport";
export default class ECSS_DynamicForm extends LightningElement {

    @api objectName;
    @api recordId;
    @api fieldSet;


    @track fieldsList =[];
    @track originalValues = {};
    
    @track isLoading = false;
    @track isSuccess = false;
    @track errorMessage = '';


    /* Track fields for Toast Message and Navigation
    @track objectApiName; --> used for redirection of to any custom object.
    @track toastMessage;
    @track toastTitle;
    @track toastVariant;
    @track navigationNext; // --> Used to navigate to the next screen in the flow.
    @track urlLabel; // --> Used to Display the URL Label in the toast message.*/

    @wire(getFieldSetFields, { objectName: '$objectName', fieldSetName: '$fieldSet' })
    //Call the apex method getFieldSetFields to retrieve the fields in the field set.
    wiredFields({ data, error }) {
        if (data) {
            //If the data is returned successfully, set the fieldsList to the data returned.
            this.fieldsList = data;
            console.log('Fields: '+this.fieldsList);
            this.fieldsToFetch = this.fieldsList.map(f => `${this.objectName}.${f}`);
            console.log('fieldsToFetch: '+this.fieldsToFetch);
            //Get the record data for the fields in the field set.
            this.loadOriginalValues();
        } else if (error) {
            console.error('Error loading field set fields:', error);
        }
    }

    loadOriginalValues() {

        console.log('this.fieldsList.length'+this.fieldsList.length);
        console.log('recordId: '+this.recordId);
        console.log('fieldsList: '+this.fieldsList);

        //If the recordId or fieldsList is not set, exit the method.
        if (!this.recordId || !this.fieldsList.length) return;

        console.log('this.objectName: '+this.objectName);
        console.log('this.record: '+this.record);

        //Get the record data for the fields in the field set.
        getRecordData({ObjectName: this.objectName ,recordId: this.recordId , fieldsList: this.fieldsList}).then(result => {
            //Capture the original values of the fields in the field set.
            this.originalValues = result;
            console.log('originalValues: '+this.originalValues);
            console.log('Original Values: '+JSON.stringify(this.originalValues));
        }).catch(error => {
            console.log('Error loading record data:', error);
        });
    }
     handleSubmit(event) {
        //event.preventDefault();
        this.isLoading = true;
        this.isSuccess = false;
        const fields = event.detail.fields;
        if(fields.DualCitizenship__c == 'Yes' && (fields.Nationality__pc == fields.SecondaryCitizenshipCountry__c)|| fields.SecondaryCitizenshipCountry__c == '')
        {
            this.errorMessage = 'Secondary Citizenship is mandatory. and it should not be same as Nationality.';
        }
        console.log('Fields: '+JSON.stringify(fields));
        console.log('Error Message: '+this.errorMessage);
        //this.template.querySelector('lightning-record-edit-form').submit(fields);

    }

    handleSuccess(event){
        this.isLoading = false;
        this.isSuccess = true;
        this.errorMessage ='';
        console.log('Record updated', event.detail.id);
        //Create a toast event to display the success message with a link to the Field Update Request record.
        const toastEvent = new ShowToastEvent
        ({
            "title": 'Success',
            "variant": 'success',
            "message": 'The '+this.objectName + 'has been updated successfully.'
        });
    }
    handleError(event) {
        this.isLoading = false;
        this.isSuccess = false;

        console.log('Full error object:', JSON.stringify(event.detail, null, 2));

        let message = event?.detail?.message || 'An unexpected error occurred while saving.';

        if (event?.detail?.output?.errors && event.detail.output.errors.length > 0) {
            message = event.detail.output.errors[0].message;
        }

        if (event?.detail?.output?.fieldErrors) {
            const fieldErr = Object.values(event.detail.output.fieldErrors);
            if (fieldErr.length > 0 && fieldErr[0].length > 0) {
                message = fieldErr[0][0].message;
            }
        }

        if (!this.errorMessage) {
            this.errorMessage = message;
        }

        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: this.errorMessage,
                variant: 'error'
            })
        );
    }

}