import { LightningElement, api, track } from 'lwc';
import updateStatus from '@salesforce/apex/ManageRequestController.updateStatus';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import VATConsent from '@salesforce/label/c.BPM_VATConsent_Message';
import BankDetailsConsent from '@salesforce/label/c.BPM_BankAccount_Consent';

export default class MarketingReimbursementModal extends LightningElement {
    @api brokerRequestId
    @api enableAction;
    brokerInvoiceURL;
    urlPrefix ='/BrokerMarketingReimbursementPDF?brokerRequestId=';
    @track showSpinner = false;
    commentRequired = false;
    comments = '';
    statusValue;
    isOpenConsentModal = false;
    isVatChecked = false;
    isBankConsentChecked = false;
    enableConsentSubmit = false;

    label = {
        VATConsent,
        BankDetailsConsent
    }; 

    connectedCallback(){
        this.showSpinner = true;
        this.brokerInvoiceURL = '..'+this.urlPrefix+this.brokerRequestId; 
        `url(..${this.urlPrefix+this.brokerRequestId})` ;
        this.showSpinner = false;
    }

    closeModal(){
        this.dispatchEvent(new CustomEvent('close', {detail:{isOpen:false}}));
    }

    handleDownload(){
        window.open(this.brokerInvoiceURL+'&renderVal=pdf', "_blank");P
    }

    handleStatusChange(event){
        var statusValue = event.target.name;
        if(statusValue === 'Rejected'){
            this.commentRequired = true;
            this.statusValue = 'Rejected';
            this.template.querySelectorAll('.inputComments').forEach(element => {
                element.reportValidity();
                element.scrollIntoView();
            });
            this.handleSubmit();            
        }else{
            this.statusValue = 'Pending Invoice Verification';
            this.commentRequired = false;
            this.isOpenConsentModal = true;
        }
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    handleCheck(event){
        if (event.target.dataset.id === 'VATConsent') {
            this.isVatChecked = event.target.checked;
        }
        if (event.target.dataset.id === 'BankDetailsConsent') {
            this.isBankConsentChecked = event.target.checked;
        }

        if(this.isVatChecked && this.isBankConsentChecked){
            this.enableConsentSubmit = true;
        }else{
            this.enableConsentSubmit = false;
        }        
    }

    closeConsentModal(event){
        this.isOpenConsentModal = false;
    }

    async handleSubmit(){
        if((!this.commentRequired) ||  
            (this.template.querySelector('.inputComments').value && 
            this.template.querySelector('.inputComments').value != '')){
            
            if(this.statusValue){
                this.showSpinner = true;

                await updateStatus({
                    recordId : this.brokerRequestId, 
                    statusValue : this.statusValue, 
                    comment : this.template.querySelector('.inputComments').value 
                })
                .then(data => {
                    this.showToast('Submitted ', 'Your request has been submitted successfully!', 'success' );

                    this.dispatchEvent(new CustomEvent('close', {detail:{isOpen:false}}));
                    this.showSpinner = false;
                    location.reload();
                })
                .catch(error => {
                    this.showToast('Error: ', error.body.message, 'error' );
                    console.error(error);
                    this.dispatchEvent(new CustomEvent('close', {detail:{isOpen:false}}));
                    this.showSpinner = false;
                });
            }
        }
    }   
}