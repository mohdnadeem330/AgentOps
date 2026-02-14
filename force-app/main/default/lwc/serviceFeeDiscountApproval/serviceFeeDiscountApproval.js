import { LightningElement,track,api,wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecord } from 'lightning/uiRecordApi';

const FIELDS = ['Opportunity.Amount','Opportunity.FirstMethodofContact__c'];
export default class ServiceFeeDiscountApproval extends LightningElement {
    @api recordId;  
    @track isFileUploadRequired = false; 
    @track isFileUploaded = false;       
    @track isFileUploadError = false;
    @track sellerServiceChargePostAmount = 0;
    @track buyerServiceChargePostAmount = 0;  
    @track leadFromBroker = true;
    @track amount = 0;  
    @track smcomment = false;


    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            
            if(data.fields.FirstMethodofContact__c.value==='Broker Portal'){
                this.leadFromBroker = false;
            }else{
                this.leadFromBroker = true;
            }
            this.amount = data.fields.Amount.value;
            console.log('Amount:'+this.amount);
            console.log('leadFromBroker:'+this.leadFromBroker);
        } else if (error) {
            console.error('Error retrieving record:', error);
        }
    }

    handleServiceChargeChange(event) {
        
        const selectedValue = event.target.value; 
        this.sellerServiceChargePostAmount = this.amount - (this.amount * selectedValue)/100;
        console.log('this.sellerServiceChargePostAmount:'+this.sellerServiceChargePostAmount);
        
    }
    handlebuyerChargeChange(event) {
        
        const selectedValue = event.target.value; 
        this.buyerServiceChargePostAmount = this.amount - (this.amount * selectedValue)/100;
        console.log('this.buyerServiceChargePostAmount:'+this.buyerServiceChargePostAmount);
        
    }

     handleSalesManagerComment(event) {
        
        const selectedValue = event.target.value; 
        if(selectedValue == undefined || selectedValue =='' || selectedValue == null)
             this.smcomment = false;
        else
            this.smcomment = true;
        
    }

    handleSubmit(event) {
         if(!this.smcomment){
            event.preventDefault(); 
            console.log('prevent default');
        } else  
            this.closeQuickAction();
       
    }

    closeQuickAction() {
        const closeQuickActionEvent = new CustomEvent('close');
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleSuccess(event) {

        if(!this.smcomment){
            event.preventDefault(); 
            console.log('prevent default');
        } else{
            const updatedRecordId = event.detail.id;
            console.log('Record created/updated with ID:', updatedRecordId);
            this.closeQuickAction();
        }
    }
}