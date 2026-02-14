import { LightningElement, api, track } from 'lwc';
import getCommissionTrail from '@salesforce/apex/InvoiceBundleController.getCommissionTrail';
import updateStatus from '@salesforce/apex/InvoiceBundleController.updateStatus';
import { NavigationMixin } from 'lightning/navigation';
import BP_BANKDETAILS_NOTFOUND from '@salesforce/label/c.BP_BANKDETAILS_NOTFOUND';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import VATConsent from '@salesforce/label/c.BPM_VATConsent_Message';
import BankDetailsConsent from '@salesforce/label/c.BPM_BankAccount_Consent';

export default class ManageInvoicesBundleModal extends LightningElement {
    @api commissionRecordId;
    @api invoiceRecordId;
    @api invoiceName;
    @api enableAction;
    @api bankDetailsAvailable;
    brokerInvoiceURL;
    urlPrefix ='/BrokerInvoiceBundlePDF?invoiceId=';
    @track showSpinner=false;
    commentRequired=false;
    comments='';
    isOpenConsentModal = false;
    label = {BP_BANKDETAILS_NOTFOUND};
    isVatChecked;
    isBankConsentChecked;
    isLegalChecked;
    enableConsentSubmit = false;
    statusValue;

    label = {
        VATConsent,
        BankDetailsConsent
    }; 

    connectedCallback(){
        console.log('this.invoiceRecordId:::'+this.invoiceRecordId);
        this.showSpinner=true;
        this.brokerInvoiceURL = '..'+this.urlPrefix+this.invoiceRecordId; `url(..${this.urlPrefix+this.invoiceRecordId})` ;
        this.showSpinner=false;
        this.getTrails();
    }
    getTrails(){
        getCommissionTrail({recordId:this.invoiceRecordId})
        .then(data => {
            this.comments = data;
        })
        .catch(error => {
            console.error(error);
        });
    }
    closeModal(){
        this.dispatchEvent(new CustomEvent('close', {detail:{isOpen:false}}));
    }
    handleDownload(){
        window.open(this.brokerInvoiceURL+'&renderVal=pdf', "_blank");
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
            //bankDetailsAvailable is not considered as boolean
            this.statusValue = 'Pending Invoice Verification';
            this.commentRequired=false;
            if(this.bankDetailsAvailable === 'false'){
                this.showToast('Error', BP_BANKDETAILS_NOTFOUND, 'error');
            }else{
                this.isOpenConsentModal = true;
            }
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

    handleSubmit(){
        
        if((!this.commentRequired && this.bankDetailsAvailable === 'true') ||  (this.template.querySelector('.inputComments').value && this.template.querySelector('.inputComments').value!='')){
            if(this.statusValue){
                this.showSpinner=true;
                updateStatus({recordId : this.invoiceRecordId  , statusValue : this.statusValue, comment :this.template.querySelector('.inputComments').value })
                    .then(data => {
                        this.dispatchEvent(new CustomEvent('close', {detail:{isOpen:false}}));
                        this.showSpinner=false;
                    })
                    .catch(error => {
                        console.error(error);
                        this.dispatchEvent(new CustomEvent('close', {detail:{isOpen:false}}));
                        this.showSpinner=false;
                    });
            }
        }
    }   

}