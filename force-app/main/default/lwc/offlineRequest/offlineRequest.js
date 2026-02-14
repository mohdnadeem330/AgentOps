import { LightningElement,track } from 'lwc';
import getOfflineRequests from "@salesforce/apex/OfflineRequestController.getOfflineRequest";
import sendforApproval from "@salesforce/apex/OfflineRequestController.sendManagerApprovel";
import getCurrentApproveRequest from "@salesforce/apex/OfflineRequestController.checkApprovedRequest";
import validateOfflineRequest from "@salesforce/apex/OfflineRequestController.validateOfflineRequest";
import cancelOffRequest from "@salesforce/apex/OfflineRequestController.cancelOffRequest";
import deleteOffRequest from "@salesforce/apex/OfflineRequestController.deleteOffRequest";
import Id from '@salesforce/user/Id';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
const actions = [
    { label: 'Edit', name: 'Edit' },
    { label: 'Delete', name: 'Delete' },
    { label: 'Cancel', name: 'Cancel' }
];
const columns = [
   // { label: 'Name', fieldName: 'Name' },
    { label: 'Start Date & Time', fieldName: 'startTime', type: 'date', typeAttributes: {
        day: 'numeric',
        month: 'short',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
        //second: '2-digit',
        hour12: true
      }, },
    { label: 'End Date & Time', fieldName: 'endTime', type: 'date',typeAttributes: {
        day: 'numeric',
        month: 'short',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
        //second: '2-digit',
        hour12: true
      } },
    { label: 'Reason', fieldName: 'reason', type: 'text' },
    { label: 'Status', fieldName: 'Status', type: 'text' },
    {
        type: 'action',
        typeAttributes: { rowActions: actions },
    },
];
export default class OfflineRequest extends LightningElement {
    objectApiName = 'OfflineRequest__c';
    recordId = '';
    today;
    showCreateOfflineRequest = false;
    @track toggleChecked = true; 
    showOfflineStatus = true;
    showCreateOfflineRequestList = true;
    offlineRequestData = [];
    columns = columns;
    showSpinner = true;
    progress = 5000;
    showDeleteConfirmation = false;
    showCancleConfirmation = false;
    selectedRow ;
    connectedCallback(){
        this.today  = (new Date().getDate()) +'/'+(new Date().getMonth())+'/'+new Date().getFullYear();
        console.log('today>>>>',this.today);
        this.populateOfflineRequest();
        this.checkCurrentOfflineRequest();
        /*
        this._interval = setInterval(()=>{
         this.checkCurrentOfflineRequest();
        },this.progress);
        */
    }

    async checkCurrentOfflineRequest(){
        this.showOfflineStatus = false;
        let approvedOffLineRequest = await getCurrentApproveRequest();
        console.log('approvedOffLineRequest>>>>>>',approvedOffLineRequest);
        if(approvedOffLineRequest.workingHours == true){
            if(approvedOffLineRequest.approvedOfflineReq.length == 0){
                this.toggleChecked = true;
                this.showOfflineStatus = true;
            }else{
                this.toggleChecked = false;
                this.showOfflineStatus = true;
            }
            
        }else{
            this.toggleChecked = false;
            this.showOfflineStatus = true;
        }
    }

    populateOfflineRequest(){
        getOfflineRequests()
        .then(data => {
            this.offlineRequestData = data;
            this.showSpinner = false;
            
        })
        .catch(error => {
            
            this.showToast('Error!.',JSON.stringify(error),'error');
            this.offlineRequestData = undefined;
            this.showSpinner = false;
        });
    }

    hanldeSubmit(event){
        event.preventDefault();     
        var fields = event.detail.fields;
        console.log('field>>>>>>',fields);
        fields.User__c = Id;
        fields.Status__c = 'Awaiting approval';
        this.validateOfflineRequest(fields);
        //this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    async validateOfflineRequest(fields){
        let validateResults = await validateOfflineRequest({objOfflineRequest:fields});
        console.log('validateResults>>>>>',validateResults);
        let isSuccess = true;
        if(validateResults.startTimeValidate == false){
            this.showToast('Warning.','Start Time is not with in the Business hours','error');
            isSuccess = false;
        }
        if(validateResults.endTimeValidate == false){
            this.showToast('Warning.','End Time is not with in the Business hours','error');
            isSuccess = false;
        }
        if(validateResults.existingOfflineRequest.length > 0){
            this.showToast('Warning.','Existing Offline Request still in progress.','error');
            isSuccess = false;
        }
        if(isSuccess){
            this.template.querySelector('lightning-record-edit-form').submit(fields);
        }
    }
    handleCancel(){
        this.showCreateOfflineRequest = false;
    }
    handleOnClick(){
        this.showCreateOfflineRequest = true;
    }
    handleToggle(event){
        this.showOfflineStatus = false;
        console.log('this.handleToggle>>>>>>>',this.handleToggle);
        let checkboxChecked = event.target.checked;
        if(checkboxChecked == false){
            this.showToast('Warning.','You can not go offline without Manager Approval.','error');
            this.toggleChecked = true;
            this.showOfflineStatus = true;
        }
        if(this.toggleChecked == false && checkboxChecked == true){
            //Need to write the logic.
            this.showOfflineStatus = true;
        }
        
        
        console.log('checkboxChecked>>>>>',checkboxChecked);
    }

    handleSuccess(event) {
        this.showSpinner = true;
        let offlineRequestId = event.detail.id;
        this.showToast('Success.','Offline Request created Successfully.','success');
        this.showCreateOfflineRequest = false;
        this.submitforApproval(offlineRequestId);
        this.populateOfflineRequest();
        
    }

    submitforApproval(offlineRequestId){
        sendforApproval({offLineRequestId:offlineRequestId})
        .then(result =>{
            this.showToast('Success.','Offline Request sent for the Line Manager Approval','success');
            this.showSpinner = false;
        })
        .catch(error => {

            console.log('error>>>>>>',error);
            this.showToast('Error!.',JSON.stringify(error),'error');
            this.offlineRequestData = undefined;
            this.showSpinner = false;
        });
    }
    
    handleError(event){
       console.log(event.detail.detail);
       // this.showToast('Error!', JSON.stringify(event.error) , 'error');
        this.showSpinner = false;
    }

    handleRowAction( event ) {

        const actionName = event.detail.action.name;
        const row = event.detail.row;
        console.log('row>>>>>',row);
        this.showSpinner = true;
        switch ( actionName ) {
            case 'Cancel':
                if(row.cancel){
                    this.showCancleConfirmation = true;
                    this.selectedRow = row;
                }else{
                    this.showToast('Error.','You can not cancel this Offline Request','error');
                    this.selectedRow = null;
                    this.showSpinner = false;
                }
                break;
            case 'Edit':
                if(row.editable){
                    this.showCreateOfflineRequest = true;
                    this.recordId = row.Id;
                }else{
                    this.showToast('Error.','You can not Edit this Offline Request','error');
                    this.showSpinner = false;
                }
                break;
            case 'Delete':
                if(row.deletable){
                    this.showDeleteConfirmation = true;
                    this.selectedRow = row;
                }else{
                    this.showToast('Error.','You can not Delete this Offline Request','error');
                    this.selectedRow = null;
                    this.showSpinner = false;
                }
                default:
            }
            this.populateOfflineRequest();
    
    }
    handleCancelNoButton(){
        this.showCancleConfirmation = false;
        
    }
    handleDelNoButton(){
        this.showDeleteConfirmation = false;
        
    }
    handleDelYesButton(){
        console.log('selectedRow>>>>>>>',this.selectedRow);
        deleteOffRequest({objOfflineRequest:this.selectedRow})
        .then(result =>{
            this.showToast('Success.','Offline Request Canceled successfully.' ,'success');
            this.showSpinner = false;
            this.selectedRow = null;
            this.showDeleteConfirmation = false;
            this.populateOfflineRequest();
        })
        .catch(error => {

            console.log('error>>>>>>',error);
            this.showToast('Error!.',JSON.stringify(error),'error');
            this.offlineRequestData = undefined;
            this.showSpinner = false;
        });
    }
    handleCancelYesButton(){
        console.log('selectedRow>>>>>>>',this.selectedRow);
        
        cancelOffRequest({objOfflineRequest:this.selectedRow})
        .then(result =>{
            this.showToast('Success.','Offline Request Canceled successfully.' ,'success');
            this.showSpinner = false;
            this.selectedRow = null;
            this.showCancleConfirmation = false;
            this.populateOfflineRequest();
        })
        .catch(error => {

            console.log('error>>>>>>',error);
            this.showToast('Error!.',JSON.stringify(error),'error');
            this.offlineRequestData = undefined;
            this.showSpinner = false;
        });
    }
    showToast(title, msg, type) {
        const event = new ShowToastEvent({
            title: title,
            message: msg,
            variant : type
        });
        this.dispatchEvent(event);
    }
}