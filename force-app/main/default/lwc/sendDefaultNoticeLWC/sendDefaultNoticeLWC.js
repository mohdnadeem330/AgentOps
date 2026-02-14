import { LightningElement,api } from 'lwc';
import CallSendDefault from '@salesforce/apex/DefaultAndTerminationUtility.CallfromSendDefaultlwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import SuccessLabel from '@salesforce/label/c.DefaultNoticeSuccessMessage';
import ErrorLabelName from '@salesforce/label/c.DefaultNoticeErrrorMessage';
import { CloseActionScreenEvent } from 'lightning/actions';
import { loadScript, loadStyle } from "lightning/platformResourceLoader";
import scriptresource from "@salesforce/resourceUrl/dntCss";
import { getRecordNotifyChange } from "lightning/uiRecordApi";

export default class CallSendDefaultlwc extends LightningElement {
    @api recordId
    @api isnotLoading = false;
    @api objectApiName;

    connectedCallback() {
    
            loadStyle(this, scriptresource) 
            .then(() => console.log('Loaded style'))
            .catch(error => console.log('error'+error.body.message));
        
         
        // loadScript(this, scriptresource)
        // .then(() => console.log('Loaded style'))
        // .catch(error => console.log('error'+error.body.message));
    }
    onSubmithandler(event) {
        
        this.isnotLoading = true;
        const inputField = this.template.querySelector('lightning-input-field');
        const value = inputField.value;
        if (!value) {
            // Display error toast
            this.isnotLoading = false;
            this.showToast('Error', 'Default Reason is required.', 'error');
            event.preventDefault();
        } else {
       this.template.querySelector('lightning-record-edit-form').submit();
        
        CallSendDefault({installmentid: this.recordId})
        .then(result =>{
            this.isnotLoading = false;
            this.showToast('Success', SuccessLabel, 'success'); 
          
           // location.reload();  
            this.dispatchEvent(new CloseActionScreenEvent());
            getRecordNotifyChange([{ recordId: this.recordId }]);
                
        })
        .error(error =>{
            this.isnotLoading = false;
            this.showToast('Error', ErrorLabelName, 'error');
            console.log('error' + error)
           this.dispatchEvent(new CloseActionScreenEvent());
        })
    }

    }
    handleSuccess(event) {
        this.dispatchEvent(new CloseActionScreenEvent());
      //  location.reload();
   }
   closeActionHandler(){
    this.dispatchEvent(new CloseActionScreenEvent());
   }

    showToast(title, message, variant){
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            // mode: 'sticky'
        });
        this.dispatchEvent(evt);
      // this.dispatchEvent(new CloseActionScreenEvent());
    }
}