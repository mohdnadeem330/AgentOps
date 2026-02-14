import { LightningElement, api } from 'lwc';

export default class AldAskConfirmation extends LightningElement {

    @api inputObj = {};
    @api uiFor;
    newInputObj = {};
    okClass = 'slds-button slds-button_brand ';
    cancelClass = 'slds-button xx_cancel';
    
    connectedCallback() {
        this.newInputObj = {...this.inputObj};
        let forSalesManager = this.newInputObj.forSalesManager ? '' : 'xx_actionbuttons';
        let baseclass = this.uiFor == 'salesforce' ? 'slds-button ' : 'aldar-btn';
        this.okClass = forSalesManager+' '+baseclass+' slds-button_brand aldar-btn-black-bg xx_m-right-large slds-m-left_medium'; //aldar-btn-black-bg will work only in portal
        this.cancelClass = forSalesManager+' '+baseclass+' slds-button_outline-brand xx_m-left-large';
    }
    handleAccept(event) {
        this.newInputObj.accepted = true;
        this.newInputObj.declined = false;
        this.newInputObj.cancelReason = '';
        this.newInputObj.cancelComment = '';
        this.dispatchEvent(new CustomEvent('confirmation', { detail: this.newInputObj }));
    }

    handleCloseModal(event) {
        this.newInputObj.accepted = false;
        this.newInputObj.declined = true;
        this.dispatchEvent(new CustomEvent('confirmation', { detail: this.newInputObj }));
    }
}