import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue, getRecordNotifyChange } from 'lightning/uiRecordApi';
import updateCase from '@salesforce/apex/dmUpdateCaseHandler.updateCase';
import getSubStatusDetails from '@salesforce/apex/dmUpdateCaseHandler.getSubStatusDetails';
import getUserInfo from '@salesforce/apex/DM_UtilityController.getUserInfo';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import OWNER_FIELD from "@salesforce/schema/Case.OwnerId";
import CREATEDBY_FIELD from "@salesforce/schema/Case.CreatedById";
import PAYMENTREQ_FIELD from "@salesforce/schema/Case.Payment_Required__c";
import AMOUNT from "@salesforce/schema/Case.Service_Price__c";
import CASENUMBER_FIELD from "@salesforce/schema/Case.CaseNumber";
import SUBSTATUS from "@salesforce/schema/Case.Sub_Status__c";
import Dm_PaymentCtrlProfile from '@salesforce/label/c.Dm_PaymentCtrlProfile';
import DM_2ndLevelApproverProfile from '@salesforce/label/c.DM_2ndLevelApproverProfile';
import getDmApprovalUsers from '@salesforce/apex/dmUpdateCaseHandler.getDMApproverUsers';
import getCaseInfo from '@salesforce/apex/dmUpdateCaseHandler.getCaseInfo';
import getDMFinalApproverUserInfo from '@salesforce/apex/dmUpdateCaseHandler.getDMFinalApproverUserInfo';
import { CurrentPageReference } from 'lightning/navigation';
import postToChatter from '@salesforce/apex/dmUpdateCaseHandler.postToChatter';

 
export default class DmUpdateCaseStatus extends LightningElement {
    disableSubmitBtn = false;
    isLoading = false;
    @api recordId;
    caseObj;
    comments;
    showComments = false;
    showRejReason = false;
    showPaymentReq = false;
    showAmount = false;
    btnLabel = 'Update';
    showGenDocwoPay = false;
    // callOnce=true;
    subStatusValue;
    statusOptions = [];
    userInfo;
    approverList = [];
    showApprover = false;
    approverAction;
    showStatus = true;
    @track initialApproverList = [];
    @track finalApproverList = [];
    showSkipApprover = true;
    @track selectedApprover = '';
    approverLabel = 'Next Approver';
    caseDetails;
   

 
    connectedCallback() {
        this.caseObj = new Object;
        this.caseObj.SobjectType = 'Case';
        this.getCaseInfoDetails();
        this.getDMFinalApproverUserInfo();
        this.getDMApproverUsersInfo();
    }
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId || this.recordId;
        }
    }
 
    getCaseInfoDetails(){      
        getCaseInfo({ recordId: this.recordId })
            .then(result => {              
                this.caseDetails=result;                          
                this.getUserDetails();
            }).catch(err=>{
                console.log('error',err);
            });                
    }
   
    renderedCallback() {
        /*  if(this.paymentReqValue && this.callOnce){
 
              if (this.paymentReqValue == 'Yes'){
                  this.showAmount = true;
                  this.showGenDocwoPay=false;
                  this.btnLabel='Initate Payment';
               } else{
                  this.showAmount = false;
                  this.showGenDocwoPay=true;
                  this.btnLabel='Generate Document';
              }
              this.callOnce = false;
          }  */
 
    }
    getUserDetails() {
        getUserInfo()
            .then(data => {
                console.log(this.caseDetails)
                this.userInfo = data[0];                                
                if (Dm_PaymentCtrlProfile.includes(this.userInfo.Username) && this.caseDetails.Sub_Status__c =='Approved') {
                    this.showStatus = false;
                    this.showPaymentReq = true;
                }
 
            })
            .catch(error => {
                //console.log('error-->' + error.message);
            });
    }
    @wire(getRecord, {
        recordId: '$recordId',
        fields: [OWNER_FIELD, CREATEDBY_FIELD, PAYMENTREQ_FIELD, AMOUNT, SUBSTATUS, CASENUMBER_FIELD]
    })
    caseInfo;
 
    @wire(getSubStatusDetails, { recId: '$recordId', sObjectName: 'Case' })
    accountsData({ error, data }) {
        if (data && data.length > 0) {
            let subStatusVal = data[0].NextApplicableStatus__c.split(',');
            this.statusOptions = subStatusVal.map(item => ({
                label: item,
                value: item
            }));
        }
        if (error) {
            console.log('error' + JSON.stringify(error))
        }
    }
 
    get amountValue() {
        return getFieldValue(this.caseInfo.data, AMOUNT);
    }
 
    get paymentReqValue() {
        const payVal = getFieldValue(this.caseInfo.data, PAYMENTREQ_FIELD);
        if (payVal == 'Yes') {
            this.showAmount = true;
            this.showGenDocwoPay = false;
            this.btnLabel = 'Initate Payment';
        }
        return payVal;
    }
    get paymentValues() {
        return [
            { label: 'Yes', value: 'Yes' },
            { label: 'No', value: 'No' },
        ];
    }
    getDMApproverUsersInfo() {
        getDmApprovalUsers()
            .then(data => {
                if (data) {
                    this.initialApproverList = data.map(user => ({
                        label: user.Name,
                        value: user.Id
                    }));
                    this.approverList = this.initialApproverList;
                }
            })
            .catch(error => {
                console.error('Error fetching PMC portal users:', error);
            });
    }
    getDMFinalApproverUserInfo() {
        getDMFinalApproverUserInfo()
            .then(data => {
                if (data) {
                    this.finalApproverList = data.map(user => ({
                        label: user.Name,
                        value: user.Id
                    }));
                    this.approverList = this.finalApproverList;
                }
            })
            .catch(error => {
                console.error('Error fetching PMC portal users:', error);
            });
    }
    setDefaultApprover() {
        if (this.approverList.length > 0) {
            this.selectedApprover = this.approverList[0].value;
            this.caseObj.Assigned_To__c = this.selectedApprover;
            this.nextApproverId = this.selectedApprover;
        }
    }
    /*  get statusOptions() {
         return [
             { label: 'Additional Information Required from Customer', value: 'Additional Information Required from Customer' },
             { label: 'Additional Information Required from PMC', value: 'Additional Information Required from PMC' },
             { label: 'Document Approved by DM Manager', value: 'Document Approved by DM Manager' },
             { label: 'Rejected by DM Manager', value: 'Rejected by DM Manager' },
         ];
     } */
    handleChange(event) {
        if (event.target.name == 'comments')
            this.comments = event.target.value;
        else if (event.target.name == 'Service_Price__c') {
            this.caseObj[event.target.name] = event.target.value;
            this.template.querySelector('[data-id="amtWarningMsg"]').classList.remove('slds-hidden');
        } else if (event.target.name == 'approver') {
            this.nextApproverId = event.target.value;
            this.caseObj.Assigned_To__c = event.target.value;
        } else
            this.caseObj[event.target.name] = event.target.value;
 
        if (event.target.name == 'Sub_Status__c') {
 
            if (event.target.value == 'Additional Information Required from Customer' || event.target.value == 'Additional Information Required from PMC')
                this.showComments = true;
            else
                this.showComments = false;
            if (event.target.value == 'Rejected')
                this.showRejReason = true;
            else
                this.showRejReason = false;
               
            if (Dm_PaymentCtrlProfile.includes(this.userInfo.Username) && this.caseDetails.Sub_Status__c =='Approved') {                 
                this.showPaymentReq = true;
                this.showApprover = false;
                if (this.paymentReqValue == 'Yes') {
                    this.showAmount = true;
                    this.showGenDocwoPay = false;
                    this.btnLabel = 'Initate Payment';
                } else if (this.paymentReqValue == 'No') {
                    this.showAmount = false;
                    this.showGenDocwoPay = true;
                    this.btnLabel = 'Generate Document';
                }
            } else if (event.target.value == 'Rejected') {
                this.showPaymentReq = false;
                this.showAmount = false;
                this.showGenDocwoPay = false;
            } else if (event.target.value == 'Additional Information Required from Customer' || event.target.value == 'Additional Information Required from PMC') {
                this.showPaymentReq = false;
                this.showAmount = false;
                this.showGenDocwoPay = false;
            }
            else { // approved status              
                this.showPaymentReq = false;
                this.showAmount = false;
                this.showApprover = true;
                //if (DM_2ndLevelApproverProfile.includes(this.userInfo.Username) && this.caseDetails.Skip_Next_Approver__c ) {
                if (DM_2ndLevelApproverProfile.includes(this.userInfo.Username) && this.caseDetails.Sub_Status__c == 'Aldar Approval In Progress' ) {
                    this.showSkipApprover = false;
                    this.approverLabel = 'Pricing Team';
                    this.approverList = this.finalApproverList;
                    this.showComments = false;
                } /*else
                    delete this.caseObj.Sub_Status__c;*/
                this.caseObj.Assigned_To__c = this.nextApproverId;
 
            }
            if (event.target.value == 'Approved') {              
                this.approverAction = 'Approve';
                if (DM_2ndLevelApproverProfile.includes(this.userInfo.Username)) {
                    this.approverList = this.finalApproverList;
                } else
                    this.approverList = this.initialApproverList;
 
                this.setDefaultApprover();
            }
            else if (event.target.value == 'Rejected') {
                this.approverAction = 'Reject';
                this.showApprover = false;
                
            }
            else {
                this.approverAction = null; // updated this.approverAction = '';
                this.showApprover = false;
            }
        }
        if (event.target.name == 'Payment_Required__c') {
            if (event.target.value == 'Yes') {
                this.caseObj.Generate_Doc_w_o_Payment__c = false;
                this.caseObj.Service_Price__c = this.amountValue;
                this.showAmount = true;
                this.showGenDocwoPay = false;
                this.btnLabel = 'Initate Payment';
            } else {
                this.showAmount = false;
                this.showGenDocwoPay = true;
                this.caseObj.Service_Price__c = 0;
                this.btnLabel = 'Generate Document';
            }
        }
    }
    handleCheckbox(event) {
        this.caseObj[event.target.name] = event.target.checked;
        if (this.caseObj.Skip_Next_Approver__c == true) {
            this.approverLabel = 'Pricing Team';
            this.approverList = this.finalApproverList;
        } else {
            this.approverLabel = 'Next Approver';
            this.approverList = this.initialApproverList;
        }
        this.setDefaultApprover();
    }
 
    handleCaseUpdate(event) {
        
        const validData = [...this.template.querySelectorAll('lightning-textarea,lightning-combobox,lightning-input')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);
 
        if (validData) {
 
            this.isLoading = true;
            this.caseObj.Id = this.recordId;

            if (this.caseObj.Sub_Status__c == 'Rejected') {
                this.caseObj.Status = 'Rejected';
               
            }
            let feedUserId = '';


            if (this.caseObj.Sub_Status__c == 'Additional Information Required from Customer') {
                feedUserId = getFieldValue(this.caseInfo.data, CREATEDBY_FIELD);
                this.caseObj.Status = 'Pending with Customer';
            }
            if (this.caseObj.Sub_Status__c == 'Additional Information Required from PMC') {
                feedUserId = getFieldValue(this.caseInfo.data, OWNER_FIELD);
                this.caseObj.Status = 'Work In Progress';
                this.approverAction = 'Reject';
                this.caseObj.Rejected_Reason__c = this.comments.length > 255
                                                        ? this.comments.slice(0, 252).trim() + '...'
                                                        : this.comments;
            }
            if (this.caseObj.Sub_Status__c == 'Approved' && this.caseObj.Payment_Required__c == 'Yes') {
                this.caseObj.Status = 'Work In Progress';
            }
            if(this.comments != undefined && this.comments != ''){
                this.caseObj.Required_Information__c =
                this.comments.length > 255
                    ? this.comments.slice(0, 252).trim() + '...'
                    : this.comments;
            }
             
 
          //  this.caseObj.Required_Information__c = this.comments;
         
            
            this.caseObj.CaseNumber = getFieldValue(this.caseInfo.data, CASENUMBER_FIELD);;
           
            updateCase({ caseObj: this.caseObj, feedMsg: this.comments, userId: feedUserId, approverAction: this.approverAction, nextApproverId: this.nextApproverId, caseNumber: this.caseObj.CaseNumber })
                .then(result => {
                       // if (this.comments && feedUserId) {
                                        postToChatter({
                                            caseId: this.recordId,
                                            userId: feedUserId,
                                            message: this.comments
                                        });
                                    
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