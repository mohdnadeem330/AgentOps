import { LightningElement ,api, track, wire } from 'lwc';
import getVirtualAccountStatistics from '@salesforce/apex/BankVirtualAccountController.getVirtualAccountStatistics';
import createVirtualAccounts from '@salesforce/apex/BankVirtualAccountController.createVirtualAccounts';
import retryVACallout from '@salesforce/apex/BankVirtualAccountController.retryVACallout';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import resourcesPath from '@salesforce/resourceUrl/ALDARResources';
import Id from '@salesforce/user/Id';
import ProfileName from '@salesforce/schema/User.Profile.Name';
import { getRecord } from 'lightning/uiRecordApi';
import BankVirtualAccountCP from '@salesforce/customPermission/BankVirtualAccount';

export default class BankVirtualAccount extends LightningElement {
ResetIcon = resourcesPath + "/ALDARResources/svg/ResetIcon.svg";
@api recordId;
VAStatsWrapper;
TotalVA = 0;
TotalBufferVA = 0;
TotalRequestedVA = 0;
TotalFailedVA = 0;
TotalUsedVA = 0;
TotalNumberOfUnits = 0;
TotalCancelledVAs = 0;
openRequestVAModal = false;
requestForEscrowVAChecked = false;
requestForCorporateVAChecked = false;
NumberOfEscrowVAs;
NumberOfCorporateVAs;
disableSubmitRequestButton = true;
isLoading = false;
isLoadingModal = false;
userId = Id;
userProfileName;
ShowRetryButton = false;
isVAEnabled = false;
 connectedCallback(){
    this.isLoading = true;
    getVirtualAccountStatistics({recordId : this.recordId})
    .then(data => {
        this.VAStatsWrapper = data;
        this.TotalVA = this.VAStatsWrapper.TotalVA;
        this.TotalBufferVA = this.VAStatsWrapper.TotalBufferVA;
        this.TotalRequestedVA =  this.VAStatsWrapper.TotalRequestedVA;
        this.TotalFailedVA = this.VAStatsWrapper.TotalFailedVA;
        this.TotalUsedVA = this.VAStatsWrapper.TotalUsedVA;
        this.TotalNumberOfUnits = this.VAStatsWrapper.TotalNumberOfUnits;
        this.isVAEnabled = this.VAStatsWrapper.isVAEnabled;
        this.TotalCancelledVAs = this.VAStatsWrapper.CancelledVA;
        console.log('VAStatsWrapper::'+this.VAStatsWrapper);
        this.isLoading = false;
        if(this.userProfileName == 'System Administrator' && (this.TotalRequestedVA > 0 || this.TotalFailedVA > 0)){
            this.ShowRetryButton = true;
        }
       // alert(this.userProfileName+'__'+this.TotalRequestedVA);
        
    }).catch(error =>{
        console.log('error::'+error);
        this.isLoading = false;
    });
 }

 @wire(getRecord, { recordId: Id, fields: [ProfileName] })
    userDetails({ error, data }) {
        if (error) {
            this.error = error;
        } else if (data) {
            if (data.fields.Profile.value != null) {
                this.userProfileName = data.fields.Profile.value.fields.Name.value;
                if(this.userProfileName == 'System Administrator' && (this.TotalRequestedVA > 0 || this.TotalFailedVA > 0)){
                    this.ShowRetryButton = true;
                }
            }
        }
    }

 handleRefresh(){
    this.connectedCallback();
 }
 handleRequestVA(event){
   this.openRequestVAModal = true;
 }
 closeModal(){
    this.openRequestVAModal = false;
    this.requestForEscrowVAChecked = false;
    this.requestForCorporateVAChecked = false;
    this.NumberOfEscrowVAs = null;
    this.NumberOfCorporateVAs = null;
 }
  handleChange(event){
    this.disableSubmitRequestButton = true;
    if(event.target.name == 'escrowVACheck'){
        this.requestForEscrowVAChecked = event.target.checked;
        if(!event.target.checked){
            this.NumberOfEscrowVAs = null;
        }
    }else if(event.target.name == 'corporateVACheck'){
        this.requestForCorporateVAChecked = event.target.checked;
        if(!event.target.checked){
         this.NumberOfCorporateVAs = null;
        }
    }else if(event.target.name == 'NumberOfEscrowVAs'){
        this.NumberOfEscrowVAs = event.target.value;
    }else if(event.target.name == 'NumberOfCorporateVAs'){
        this.NumberOfCorporateVAs = event.target.value;
    }

    if( (this.NumberOfCorporateVAs != null && this.NumberOfCorporateVAs != '' && Number(this.NumberOfCorporateVAs) > 0 && Number(this.NumberOfCorporateVAs) < 1000) || (this.NumberOfEscrowVAs != null && this.NumberOfEscrowVAs != '' && Number(this.NumberOfEscrowVAs) > 0 && Number(this.NumberOfEscrowVAs) < 1000 && Number.isInteger(Number(this.NumberOfEscrowVAs)))){
        this.disableSubmitRequestButton = false;
    }
    else{
        this.disableSubmitRequestButton = true;
    }
 }
 submitRequest(){
    this.isLoading = true;
    this.isLoadingModal = true;
    var bankName;
    var NumberOfVAs;
    if(this.requestForEscrowVAChecked && this.NumberOfEscrowVAs != null) {
      if(this.VAStatsWrapper.Project != null){
        bankName = this.VAStatsWrapper.Project.BankNameEscrow__c;
      }else if(this.VAStatsWrapper.BuildingSection != null) {
        bankName = this.VAStatsWrapper.BuildingSection.BankNameEscrow__c;
      }
        NumberOfVAs = this.NumberOfEscrowVAs;

    }else if(this.requestForCorporateVAChecked && this.NumberOfCorporateVAs != null){
        if(this.VAStatsWrapper.Project != null){
        bankName = this.VAStatsWrapper.Project.BankNameCorporate__c;
        }else if(this.VAStatsWrapper.BuildingSection != null) {
            bankName = this.VAStatsWrapper.BuildingSection.BankNameCorporate__c;
          }
        NumberOfVAs = this.NumberOfCorporateVAs;
    }
    console.log('this.recordId:'+this.recordId);
    console.log('bankName:'+bankName);
    console.log('NumberOfVAs:'+NumberOfVAs);
    console.log('this.requestForEscrowVAChecked:'+this.requestForEscrowVAChecked);
    console.log('this.requestForCorporateVAChecked:'+this.requestForCorporateVAChecked);
    createVirtualAccounts({recordId:this.recordId, bankName:bankName, NumberOfVAs:NumberOfVAs,
         escrowVACheck:this.requestForEscrowVAChecked, corporateVACheck:this.requestForCorporateVAChecked})
    .then(data => {
        this.isLoading = false;
        this.isLoadingModal = false;
        
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Submitted request for Virtual Account',
                variant: 'success',
            })
        );
       this.connectedCallback();
       this.openRequestVAModal = false;
       this.requestForEscrowVAChecked = false;
       this.requestForCorporateVAChecked = false;
       this.NumberOfEscrowVAs = null;
       this.NumberOfCorporateVAs = null;
       this.disableSubmitRequestButton = true;
    }).catch(error =>{
        this.isLoading = false;
        this.isLoadingModal = false;
        console.log('error::'+error);
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: 'Something went wrong. Please contact System Administrator.',
                variant: 'error',
            })
        );
    });
 }
 handleReTry(event){
    console.log('retry');
    this.isLoading = true;
    var bankName = this.VAStatsWrapper.Project.BankNameEscrow__c;

    console.log('this.recordId:'+this.recordId);
    console.log('bankName:'+bankName);
    console.log('this.requestForEscrowVAChecked:'+this.requestForEscrowVAChecked);
    console.log('this.requestForCorporateVAChecked:'+this.requestForCorporateVAChecked);
    
    retryVACallout({recordId:this.recordId, bankName:bankName, 
        escrowVACheck:true, corporateVACheck:this.requestForCorporateVAChecked})
 
        .then(data => {
            this.isLoading = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Submitted Retry request for Virtual Account',
                    variant: 'success',
                })
            );
           this.connectedCallback();
        }).catch(error =>{
            this.isLoading = false;
            console.log('error::'+error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Something went wrong. Please contact System Administrator.',
                    variant: 'error',
                })
            );
        });
    }
    get hasBVAAccess(){
        return BankVirtualAccountCP;
    }
}