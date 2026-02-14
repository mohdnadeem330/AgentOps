import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import getApplicableSubStatus from '@salesforce/apex/reUsableSubStatusController.getSubStatusValues';
//import getApplicableRejectedReason from '@salesforce/apex/reUsableSubStatusController.getRejectedSubstatusvalue';
import getSobjectDetails from '@salesforce/apex/reUsableSubStatusController.getSobjectFieldInfo';
import saveData from '@salesforce/apex/reUsableSubStatusController.updateSobjectRec';
import { getRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';


export default class ReUsableSubStatusUpdate extends LightningElement {
    @api recordId;
    subStatusValues;
    @track selectedSubStatus;
    @track remarkValue;
     @track rmiValue;
    @track sobjectName;
    @track subStatusApiName;
    @track remarksApiName;
    @track BackupremarksApiName;
    @track backupRemark;
    @track rejectedResonValue;
    @track rejectReasonApiName;
    @track disableSavebutton=true;
    @track callOnce=true;
    @track  nextApplicableStatusOptions = [];
    @track rejectReasonsOptions = [];
    @track sobjectConfigInfo;
    @track showRejectOption=false;
     @track showRmiOption=false;
    @track isLoading=false;

renderedCallback(){
 
if(this.recordId !== undefined && this.callOnce){
this.fetchApplicableSubStatus();
}
}


fetchApplicableSubStatus() {
  getApplicableSubStatus({ recordId: this.recordId })
    .then((result) => {
      console.log(JSON.stringify(result));
      console.log(result);
      this.callOnce = false;

      if (result && result[0]) {

        if (result[0].NextApplicableStatus__c) {
          let tempArr = result[0].NextApplicableStatus__c.split(',');
          this.nextApplicableStatusOptions = tempArr.map(item => ({ label: item.trim(), value: item.trim() }));
          console.log(JSON.stringify(this.nextApplicableStatusOptions));
        }
        if (result[0].Reject_Reasons__c) {
          let tempArr2 = result[0].Reject_Reasons__c.split(',');
          this.rejectReasonsOptions = tempArr2.map(item => ({ label: item.trim(), value: item.trim() }));
          console.log(JSON.stringify(this.rejectReasonsOptions));
        }

        
      }else{
        this.dispatchEvent(new CloseActionScreenEvent());
        this.dispatchEvent(
          new ShowToastEvent({
              title: 'Warning!',
              message: 'Sub status master is not configured for your profile.',
              variant: 'warning'
          })
      );
  
      }
    })
    .catch((error) => {
      console.error('Error fetching applicable sub-status:', error);
      
    });
}


  
  

   
  /*  @wire(getApplicableSubStatus, { recordId: '$recordId' })
    wiredApplicableSubStatus({ error, data }) {
        if (data) {
          //alert('data');
            this.subStatusValues = data;
            console.log('data: ' + JSON.stringify(data));
            console.log('this.subStatus: ' + JSON.stringify(this.subStatusValues));
        } else if (error) {
            this.subStatusValues = undefined;
        }
    }*/


@wire(getSobjectDetails, { recordId: '$recordId' })
    SobjectDetails({ error, data }) {
        if (data) {
         // alert(data);
          this.sobjectConfigInfo = data;
          
         // alert(JSON.stringify(this.sobjectConfigInfo));
          this.sobjectName = data[0].MasterLabel;
        
          this.subStatusApiName = data[0].Sub_Status_API_Name__c;
          this.remarksApiName = data[0].Remarks_API_Name__c;
          this.BackupremarksApiName= data[0].Backup_Remarks_API_Name__c;
          this.rejectReasonApiName = data[0].Reject_Reason_Api_Name__c;
            console.log('datasobject'+JSON.stringify(this.BackupremarksApiName));
           
        } else if (error) {
           console.log('sobjecterror'+JSON.stringify(error));

        }
    }

   
    handleSubStatusChange(event) {
        if (event.target.label === 'Sub Status') {
          this.selectedSubStatus = event.target.value;
          this.disableSavebutton = false;
        } else if (event.target.label === 'Rejection Remarks') {
          this.remarkValue = event.target.value;
        }else if (event.target.label === 'Remarks') {
          this.rmivalue = event.target.value;
          console.log('rmi value '+this.rmivalue);
        }else if (event.target.label === 'Rejected Reason') {
          this.rejectedResonValue = event.target.value;
        }
      
        const containsRejectKeyword = this.selectedSubStatus.includes("Reject");
        if(containsRejectKeyword){
          this.showRejectOption=true;
        }else{
          this.showRejectOption=false;
        }

         const containsRmiKeyword = this.selectedSubStatus.includes("Request For More Info");
        if(containsRmiKeyword){
          this.showRmiOption=true;
        }else{
          this.showRmiOption=false;
        }
      
      }
      
    

    handleSubmit(){
      if (this.showRejectOption && !this.remarkValue) {
        this.dispatchEvent(
          new ShowToastEvent({
            title: 'Error',
            message: 'Rejected Reason is mandatory for the selected Sub Status.',
            variant: 'error'
          })
        );

        return; // Stop the submission process
      }else if(this.showRmiOption && !this.rmivalue) {
        this.dispatchEvent(
          new ShowToastEvent({
            title: 'Error',
            message: 'Remarks is mandatory for the selected Sub Status.',
            variant: 'error'
          })
        );

        return;
      }
    
      
       let obj = new Object();
       obj.sobjectType = this.sObjectName;
       obj.Id = this.recordId;
       obj[this.subStatusApiName] = this.selectedSubStatus;
       if(this.showRejectOption){
       obj[this.remarksApiName]=this.remarkValue;
       obj[this.BackupremarksApiName]=this.remarkValue;
       }else if(this.showRmiOption){
         obj[this.remarksApiName]=this.rmivalue;
       obj[this.BackupremarksApiName]=this.rmivalue;
       }
       obj[this.rejectReasonApiName]= this.rejectedResonValue;
      // obj[this.BackupremarksApiName]=this.backupRemark;
       console.log('obj'+JSON.stringify(obj));
        console.log('obj'+JSON.stringify(this.sobjectConfigInfo));
                  

        //  alert(this.sobjectConfigInfo);
         saveData({record:obj , sobjectConfigInfo:this.sobjectConfigInfo})
            .then(result => {
               console.log('record'+result);
                // Data saved successfully, handle any success actions
                this.isLoading=true;
                
                getRecordNotifyChange([{recordId: this.recordId}]);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Substatus has been changed successfully!',
                            variant: 'success'
                        })
                    );
                    this.dispatchEvent(new CloseActionScreenEvent());
                   
            })
            .catch(error => {
                // Handle any error during the data saving process
                this.dispatchEvent(new CloseActionScreenEvent());
                    getRecordNotifyChange([{recordId: this.recordId}]);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: data,
                            variant: 'error'
                        })
                    );
            });
    
    }

    handleCancel() {
        // Add your cancel button implementation here
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}