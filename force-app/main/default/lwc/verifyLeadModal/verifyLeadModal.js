import { api, LightningElement, track, wire } from 'lwc';
import DuplicateAccount_OptedApprovals from '@salesforce/label/c.DuplicateAccount_OptedApprovals';
import DuplicateAccount_SelectAccountMsg from '@salesforce/label/c.DuplicateAccount_SelectAccountMsg';
import DuplicateAccount_NoRecordsMessage from '@salesforce/label/c.DuplicateAccount_NoRecordsMessage';
import DuplicateAccount_ExistingAccVerified from '@salesforce/label/c.DuplicateAccount_ExistingAccVerified';
import DuplicateAccount_submitapprovalmsg from '@salesforce/label/c.DuplicateAccount_submitapprovalmsg';
import { CloseActionScreenEvent } from "lightning/actions";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import APPROVAL_STATUS_FIELD from "@salesforce/schema/Lead.SkipDuplicateApprovalStatus__c";
import { updateRecord } from 'lightning/uiRecordApi';
import { CurrentPageReference } from 'lightning/navigation';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import Lead from '@salesforce/schema/Lead'; 
import getDuplicateAccounts from '@salesforce/apex/VerifyLeadController.getAccounts';
import submitApprovals from '@salesforce/apex/VerifyLeadController.submitForApprovals';
import updateExistingAccountOnLead from '@salesforce/apex/VerifyLeadController.updateExistingAccountOnLead';

const fields = [APPROVAL_STATUS_FIELD];

export default class VerifyLeadModal extends NavigationMixin(LightningElement) {

    label = {
        DuplicateAccount_OptedApprovals,
        DuplicateAccount_SelectAccountMsg,
        DuplicateAccount_NoRecordsMessage,
        DuplicateAccount_ExistingAccVerified,
        DuplicateAccount_submitapprovalmsg
    }

    @api recordId;
    @track openModal = false;
    isLoading = true;
    @track selectedAccountId;
    @track dataToShow = [];
    disabled = true;
    dataLoaded = false;
    approvalsModalOpen = false;
    approvaldisabled = true;
    @track selectedReasonOption;
    @track otherReasonOption;
    disabledOtherReason = true;
    maxCharacterCount = 255;
    @track charactersRemaining = 255;

    @wire(getObjectInfo, { objectApiName: Lead })
    objectInfo;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: 'Lead.EmailApprovalsReason__c' })
    picklistValues;

    get reasonOptions() {
        console.log('this.picklistValues.data',this.picklistValues.data);
        return this.picklistValues.data ? this.picklistValues.data.values : [];
        // return [
        //     { label: 'Family/Relative', value: 'Family/Relative' },
        //     { label: 'POA Holder', value: 'POA Holder' }
        // ];
    }
    //fields = ['Email', 'SkipDuplicateApprovalStatus__c'];

    @wire(getObjectInfo, {ObjectApiName : Lead})
    getObjectData({data,error}){
        if(data){
            console.log('recordType ', JSON.stringify(data.recordTypeInfos));
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: fields})
    lead;

    get approvalStatus(){
        var status = getFieldValue(this.lead.data, APPROVAL_STATUS_FIELD);
        console.log('Statusss ',status);
        if(status === "Sent for Approval" || status === "Approved"){
            return true;
        } 
        else{return false;}
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
        } 
    }

    handleOK(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    async connectedCallback() {
        this.openModal = true;
        this.isLoading = true;
        this.getAccounts();
    }

    async getAccounts(){
        await getDuplicateAccounts({leadRecordId: this.recordId})
            .then((result) => {
                console.log('result ',JSON.stringify(result));
                const dupeWrapperData = [];
                var sortedArray = [];
                var maxSalesOrderCount = 0;
                var foundAccountWithSalesOrderCount = false;
                if (result) {
                    result.forEach(wrap => {
                        // Create a new object with the existing properties and the new one
                        const updatedWrap = {
                            ...wrap
                        };                
                        dupeWrapperData.push(updatedWrap);
                        sortedArray = [...dupeWrapperData];
                        sortedArray.sort((a, b) => b.salesOrderCount - a.salesOrderCount);
                        
                    });
                    console.log(dupeWrapperData, 'dupeWrapperData');
                    this.dataToShow = sortedArray;
                    this.isLoading = false;
                    this.dataLoaded = true;
                    this.approvaldisabled = false;
                }else{
                    this.dataToShow = [];
                    this.isLoading = false;
                    this.handleCancel();
                    const evt = new ShowToastEvent({
                        title: 'Success',
                        message: this.label.DuplicateAccount_NoRecordsMessage,
                        variant: 'success',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(evt);           
                    
                }               

            }).catch(error => {
                console.log('Error in getAccounts: ' +JSON.stringify(error));
            });
    }

    handleRowSelection(event){
        console.log('on select', event.target.value);
        this.disabled = false;
        this.selectedAccountId = event.target.value;
    }

    handleCancel(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    updateRecordView(recordId) {
        updateRecord({fields: { Id: recordId }});
    }

    handleUpdate(){
        this.isLoading = true;
        updateExistingAccountOnLead({leadRecordId: this.recordId, selectedAccountId: this.selectedAccountId})
        .then((result) => {
            const evt = new ShowToastEvent({
                title: 'Success',
                message: this.label.DuplicateAccount_ExistingAccVerified,
                variant: 'success',
                mode: 'dismissable'
            });
            this.dispatchEvent(evt);           
            this.handleCancel();
            this.isLoading = false;
            this.updateRecordView(this.recordId);
        }).catch(error => {
            console.log('Error in getAccounts: ' +JSON.stringify(error));
        });
    }

    handleApprovalsModal(){
        this.approvalsModalOpen = true;
    }
    handleChangeReason(event){
        this.selectedReasonOption = event.target.value;
    }
    handleTextareaChange(event){
        this.otherReasonOption = event.target.value;
        this.charactersRemaining = this.maxCharacterCount - this.otherReasonOption.length;
    }

    closeModalBox(){
        this.approvalsModalOpen = false;
    }

    isInputValid(){
        let isValid = true;
        let inputFields = this.template.querySelectorAll('.validate');
        inputFields.forEach(inputField => {
            if(!inputField.checkValidity()) {
                inputField.reportValidity();
                isValid = false;
            }
        });
        return isValid;
    }

    handleSubmitApprovals(){
        if(this.isInputValid()) {
        this.isLoading = true;
        submitApprovals({ 'leadId': this.recordId, 'reasonValue':this.selectedReasonOption, 'otherReason' :this.otherReasonOption})
        .then(response => {
            console.log('Response res',response);
            if(response === "MANGER_NOT_FOUND"){
                const evt = new ShowToastEvent({
                    title: 'Error',
                    message: 'Your Manager Not Found',
                    variant: 'error',
                });
                this.dispatchEvent(evt);
            }else if(response === "MANGER_NOT_ACTIVE"){
                const evt = new ShowToastEvent({
                    title: 'Error',
                    message: 'Your Manager is inActvie',
                    variant: 'error',
                });
                this.dispatchEvent(evt);
            }else if(response === "APPROVALS_ERROR"){
                const evt = new ShowToastEvent({
                    title: 'Error',
                    message: 'Record submitted for approvals already!',
                    variant: 'error',
                });
                this.dispatchEvent(evt);
            }else if(response === "SUCCESS"){
            const evt = new ShowToastEvent({
                title: 'Success',
                message: this.label.DuplicateAccount_submitapprovalmsg,
                variant: 'success',
            });
            this.dispatchEvent(evt);
            }
            this.isLoading = false;
            this.dispatchEvent(new CloseActionScreenEvent());

       }).catch(error => {
        const evt = new ShowToastEvent({
            title: 'Error',
            message: 'Error in Approval Process, Please validate Lead',
            variant: 'error',
        });
        this.dispatchEvent(evt);
        this.isLoading = false;
        console.log('Error: ' + error);
       });
    }
    }

}