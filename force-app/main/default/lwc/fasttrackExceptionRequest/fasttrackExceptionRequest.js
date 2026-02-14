import { LightningElement, track, api } from 'lwc';
import getDependentValues from '@salesforce/apex/Utilities.getDependentPickListValues';
import {FlowNavigationBackEvent , FlowNavigationNextEvent} from 'lightning/flowSupport';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class FasttrackExceptionRequest extends LightningElement {
    @api recordId;
    @track parentOptions = [];
    @track childOptions = [];
    @track selectedParent = 'Skip Fasttrack Signup';
    @track selectedChild;
    @track description = '';
    @api requestType = 'Skip Fasttrack Signup';
    @api requestReason;
    @api description;
    @track fileData;
    @api fileName;
    @api fileBase64;

    allowedParent = 'Skip Fasttrack Signup'; // <<< Only show this parent value

    mapData; // Stores full mapping

    connectedCallback() {
        getDependentValues({ objectName: 'Exception_Request__c', controllingField: 'Request_Type__c', dependentField: 'Request_Reason__c' })
            .then(result => {
                this.mapData = result;

                // Only keep ONE allowed parent
                if (result[this.allowedParent]) {
                    this.parentOptions = [
                        { label: this.allowedParent, value: this.allowedParent }
                    ];

                    let children = this.mapData[this.allowedParent];
                    this.childOptions = children.map(val => ({ label: val, value: val }));
                }

            })
            .catch(error => {
                console.error('Error:', error);
            });
    }

    handleParentChange(event) {
        this.selectedParent = event.detail.value;
        // Load its child picklist values
        let children = this.mapData[this.selectedParent];
        this.childOptions = children.map(val => ({ label: val, value: val }));
    }

    handleChildChange(event) {
        this.requestReason = event.detail.value;
    }

    handleTextChange(event) {
        this.description = event.target.value;
    }

    handleSubmit() {
        if(this.handleCheckValidation()) {
            const nextNavigationEvent = new FlowNavigationNextEvent();
            this.dispatchEvent(nextNavigationEvent);
        }
    }

    handleCheckValidation() {
        let isValid = true;
        let inputFields = this.template.querySelectorAll('.fieldvalidate');
        inputFields.forEach(inputField => {
            if(!inputField.checkValidity()) {
                inputField.reportValidity();
                isValid = false;
            }
        });
        return isValid;
    }

    handleClose() {
    }

    // getting file 
    handleFileChange(event) {
        if(event.target.files.length > 0) {
            const file = event.target.files[0]
            const acceptedTypes = ['.png','.jpg','.jpeg'];
            const fileExtension = '.' + file.name.split('.').pop().toLowerCase();

            if (!acceptedTypes.includes(fileExtension)) {
                // Display an error message to the user
                const evt = new ShowToastEvent({
                    title: 'Invalid file type',
                    message: 'Only PNG, JPG, and JPEG files are allowed.',
                    variant: 'error',
                    mode: 'dismissable'
                });
                this.dispatchEvent(evt);
                // Clear the input value to prevent the file from being processed
                event.target.value = ''; 
                return;
            }


            var reader = new FileReader()
            reader.onload = () => {
                var base64 = reader.result.split(',')[1]
                this.fileName = file.name;
                this.fileBase64 = base64;
                this.fileData = {
                    'filename': file.name,
                    'base64': base64
                }
                console.log(this.fileData)
            }
            reader.readAsDataURL(file)
        }
    }
}