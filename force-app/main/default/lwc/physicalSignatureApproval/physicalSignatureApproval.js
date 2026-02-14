import { LightningElement,track,api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class PhysicalSignatureApproval extends LightningElement {
    @api recordId;  
    @track isFileUploaded = false;       
    @track isFileUploadError = false; 
    @api selectSPASignatureType = '';   

    fields = ['SPASignaturetypechangereasonpicklist__c', 'Signaturetypechangereason__c']; 

    handleFieldChange(event) {
        
        const selectedValue = event.target.value; 
        this.selectSPASignatureType = selectedValue;
        if (selectedValue === 'Technical issue - UAE Pass/Live ALDAR') {
            this.isFileUploaded = false;
        } else {
            this.isFileUploaded = true;
        }
    }

    handleFileUploadFinished(event) {
        this.isFileUploaded = true;
        this.isFileUploadError = false;
    }

    handleSubmit(event) {
        console.log('this.isFileUploaded'+this.isFileUploaded);
        console.log('this.selectSPASignatureType'+this.selectSPASignatureType);
        if (!this.isFileUploaded && this.selectSPASignatureType.includes('Technical')){
            event.preventDefault(); 
            this.isFileUploadError = true;
        } else {
            
            this.closeQuickAction();
        }
    }

    closeQuickAction() {
        const closeQuickActionEvent = new CustomEvent('close');
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleSuccess(event) {
        const updatedRecordId = event.detail.id;
        console.log('Record created/updated with ID:', updatedRecordId);
       if(this.isFileUploadError){
            event.preventDefault(); 
            console.log('prevent default');
        } else{
            this.closeQuickAction();
       }
           
    }
}