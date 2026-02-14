import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue, getRecordNotifyChange } from 'lightning/uiRecordApi';
import updateCase from '@salesforce/apex/dmUpdateCaseHandler.updateCase';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CREATEDBY_FIELD from "@salesforce/schema/Case.CreatedById";

export default class DmTLAReqMoreInfo extends LightningElement {
    comments;
    disableSubmitBtn = false;
    isLoading = false;
    showComments = false;
    btnLabel = 'Send';
    @api recordId;
    caseObj;
    @wire(getRecord, {
        recordId: '$recordId',
        fields: [CREATEDBY_FIELD]
    })
    caseInfo;

    connectedCallback() {
        this.caseObj = new Object;
        this.caseObj.SobjectType = 'Case';
    }
    handleChange(event) {
        if (event.target.name == 'comments')
            this.comments = event.target.value;
    }

    handleCaseUpdate(event) {
        const validData = [...this.template.querySelectorAll('lightning-textarea,lightning-input')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);

        if (validData) {
            this.isLoading = true;
            this.caseObj.Id = this.recordId;
            let feedUserId = '';
            feedUserId = getFieldValue(this.caseInfo.data, CREATEDBY_FIELD);
            this.caseObj.Status = 'Pending with Customer';
            this.caseObj.Sub_Status__c = 'Additional Information Required from Customer';
            // this.caseObj.Required_Information__c = this.comments;
            this.caseObj.Required_Information__c = this.comments.length > 255
                ? this.comments.slice(0, 252).trim() + '...'
                : this.comments;

            updateCase({ caseObj: this.caseObj, feedMsg: this.comments, userId: feedUserId })
                .then(result => {
                    getRecordNotifyChange([{ recordId: this.recordId }]);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Request has been Updated Successfully',
                            variant: 'success'
                        })
                    );
                    this.dispatchEvent(new CloseActionScreenEvent());
                }).catch(error => {
                    this.isLoading = false;
                    //console.log('Error while Updating-' + JSON.stringify(error.message));
                });
        } else {
            this.isLoading = false;
        }
    }
}