import { LightningElement,wire } from 'lwc';
import getLeadDetails from '@salesforce/apex/SearchBrokerLeads.getLeadDetails';
import checkduplicateEmail from '@salesforce/apex/SearchBrokerLeads.checkduplicateEmail';
import addacocuntTeamMember from '@salesforce/apex/SearchBrokerLeads.addacocuntTeamMember';
import sentApproval from '@salesforce/apex/SearchBrokerLeads.sentforApproval';
import SearchBrokerLeadFlow  from '@salesforce/apex/SearchBrokerLeads.SearchBrokerLeadFlow';
import getExistingOpportunity  from '@salesforce/apex/SearchBrokerLeads.getExistingOpportunity';
import LEAD_OBJECT from '@salesforce/schema/Lead';
import EMAILAPPROVAL_FIELD from '@salesforce/schema/Lead.EmailApprovalsReason__c';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Id from '@salesforce/user/Id';
import { getRecord } from 'lightning/uiRecordApi';
import UserTeamFIELD from '@salesforce/schema/User.Team__c';
import AGENCY_CATEGORY_WEALTH from '@salesforce/label/c.AgencyCategoryWealth';

export default class BrokerLeadSearchcmp extends LightningElement {
    
IsOrganizationLead = false;
leadnumber;
Leadfound=null;
LeadList;
LeadId ='';
buttonclicked= false;
LeadConverted = false;
ErrormessageDisplay = false;
ErrorMessage = '';
WrapperList =[];
opportunityfound;
isVIPException=false;
isconvertDisplay = false;
    isDuplicate = false;
    isModalOpen = false;
    disabled = false;
    isExceptionOpen = false;
   
    selectedValue='';
    disabled1 = true;
    disabledReason = true;
    otherReason ='';
    ExceptionMessage = false;
    isApproved = false;
    isLoading= false;
    opportunitydata;
    isFastTrack= false;
    otherVIPReason = '';
    isVIPExceptionOpen = false;
    userId = Id;
    currentUserTeam;
    BrokerException=false;
    isBrokerException=false;
    @wire(getRecord, { recordId: Id, fields: [UserTeamFIELD]}) 
    currentUserInfo({error, data}) {
        if (data) {
            this.currentUserTeam = data.fields.Team__c.value;
        } 
    }
    @wire(getObjectInfo, { objectApiName: LEAD_OBJECT })
    leadMetadata;
   
    @wire(getPicklistValues, { recordTypeId: '$leadMetadata.data.defaultRecordTypeId', fieldApiName: EMAILAPPROVAL_FIELD })
    emailApprovalpicklist;
    get options() {
        console.log(this.emailApprovalpicklist);
        return this.emailApprovalpicklist.data?this.emailApprovalpicklist.data.values:[];
    }
 handleClick(event){
    this.isLoading = true;
     
       getLeadDetails({'LeadNumber':this.leadnumber}) // Apex class method

        .then(result =>{
            this.buttonclicked = true;
            console.log(result);
            if(result.length >0){
                
            this.isLoading = false;
            console.log(result);
            this.Leadfound = true;
            this.LeadList = result;
            this.LeadId = this.LeadList[0].Id;

            var city = '';
            if(this.LeadList[0].BrokerAgency__r.BillingState != null){
                if(this.LeadList[0].BrokerAgency__r.BillingState =='Abu Dhabi'){
                    city='AUH';
                }else if(this.LeadList[0].BrokerAgency__r.BillingState =='Dubai' || this.LeadList[0].BrokerAgency__r.BillingState =='Ajman'|| this.LeadList[0].BrokerAgency__r.BillingState =='Fujairah'||this.LeadList[0].BrokerAgency__r.BillingState =='Ras Al Khaimah'||this.LeadList[0].BrokerAgency__r.BillingState =='Sharjah' || this.LeadList[0].BrokerAgency__r.BillingState =='Umm Al Quwain')
				{
                    city='DXB';
                }else{
                //Arvind Removed the DXB City, all the international Broker will be Convert/Handle by both team

                    city='';
                }
            }
            if(this.LeadList[0].BrokerAgency__r.AgencyCategory__c == AGENCY_CATEGORY_WEALTH ){
                city = '';
            }

            if(this.LeadList[0].IsConverted == true){
                this.LeadConverted = true;
            }else if(city != '' && city != this.currentUserTeam && (this.currentUserTeam =='DXB'|| this.currentUserTeam=='AUH') && this.LeadList[0].Approval_Status__c !='Approved' && this.LeadList[0].Approval_Status__c !='Sent for Approval'){
                this.ErrormessageDisplay =true;
                this.ErrorMessage='You can not convert '+city+' Lead';
                this.BrokerException=true;
            }else if(this.LeadList[0].Approval_Status__c =='Sent for Approval'){
                this.isLoading = false;
                this.ExceptionMessage = true;
            }else{
            var EmailIdtosent = '';
            EmailIdtosent =  this.LeadList[0].Email;
            // SSC-697, Duplicate Account based on Mobile Number changes: Bashim
            var mobileNumber = '';
            mobileNumber = this.LeadList[0].MobilePhone;

            if(this.LeadList[0].ExistingAccount__c != null && this.LeadList[0].ExistingAccount__c != undefined){
                if(this.LeadList[0].ExistingAccount__r.FastTrack_Account__c== true  || (this.LeadList[0].ExistingAccount__r.FastTrack_Account__c == false && this.LeadList[0].ExistingAccount__r.ProspectAccount__c== false)){
                    this.isFastTrack= true;
                }
            }
            
            this.isModalOpen = true;
            getExistingOpportunity({ LeadNumber: this.leadnumber }).then(response => {
                console.log(response);
               if(response != null){
                var wrapper = {"OwnerfirstName":response.Owner.FirstName ,
                "OwnerLastName":response.Owner.LastName,
                "BrokerAgency": response.BrokerAgencyAccount__c != null ?  response.BrokerAgencyAccount__r.Name :''
               };
                    this.opportunitydata = wrapper;
                    this.opportunityfound = true;
                    this.isLoading = false;
               }else{
                    this.opportunityfound = false;
                    this.isLoading = false;
               }
            }).catch(error => {
                this.isLoading = false;
                console.log('Error: ' );
            });
            if(this.isFastTrack == false){
            if((this.LeadList[0].SkipDuplicateApprovalStatus__c != 'Approved' && this.LeadList[0].SkipDuplicateApprovalStatus__c != 'Sent for Approval') && this.LeadList[0].VIPApproval__c !='Sent for Approval' ){
            checkduplicateEmail({ emailId: EmailIdtosent, mobileNumber:  mobileNumber}).then(response => {
                console.log(response);
                
               if(response != null){
                    this.isLoading = false;
                   
                    //this.WrapperList = response;
                    if(response != null && response.length > 0){
                        console.log(this.WrapperList); 
                        var sortedArray = [];
                        sortedArray = [...response];
                        sortedArray.sort((a, b) => b.salesOrderCount - a.salesOrderCount);
                        this.WrapperList = sortedArray;
                        this.isDuplicate = true;
                        this.isLoading = false;
                        this.disabled = true;
                        this.isconvertDisplay = false;
                    }else{
                        this.isconvertDisplay = true;
                        this.isModalOpen = false;
                    }
               }else{
                this.isLoading = false;
                        this.isconvertDisplay = true;
                        this.isModalOpen = false;
               }
            }).catch(error => {
                this.isLoading = false;
                console.log(error);
            });
        }else if(this.LeadList[0].SkipDuplicateApprovalStatus__c == 'Sent for Approval'){
            this.isLoading = false;
            this.ExceptionMessage = true;
        }
        else if(this.LeadList[0].SkipDuplicateApprovalStatus__c == 'Approved'){
            this.isconvertDisplay = true;
            this.isLoading = false;
            this.isApproved = true;
        }
        if(this.LeadList[0].VIPApproval__c =='Sent for Approval'){
            this.isLoading = false;
            this.ExceptionMessage = true;
        }
         // Org lead converting to person account changes 

        if(this.LeadList[0].RecordType.Name == 'Organization'){

            this.isLoading = false;

            this.IsOrganizationLead = true;

        }
        
    }else{
        this.isconvertDisplay = true;
            this.isLoading = false;
            this.isApproved = true;
    }
        }
        }else{
            this.isLoading = false;
            this.Leadfound = false;
        }
            
        })
        .catch(error =>{
            console.log(error);
            this.isLoading = false;
           // this.errorMsg = error;
        })
      

    } 
    updateleadnumber(event){
        this.leadnumber = event.target.value.trim();
    }
    hideModalBox(event){
        this.isExceptionOpen = false;
        this.isVIPExceptionOpen = false;
        this.isBrokerException=false;
    }

    handleRowSelection(event){
        
        console.log('on select', event.target.value);
        this.disabled1 = false;
        this.selectedAccountId = event.target.value;
    }
    handleUpdate(event){
        this.isLoading = true;
        addacocuntTeamMember({ recordId: this.selectedAccountId,LeadId: this.LeadId,LeadNumber: this.leadnumber }).then(response => {
            if(response == null || response ==''){
            this.isLoading = false;
            this.LeadConverted = true;
            this.isDuplicate = false;
            this.ExceptionMessage = false;
            
             window.open('/'+this.selectedAccountId,'_self');
            }else{
                const evt = new ShowToastEvent({
                    title: 'Error',
                    message: response,
                    variant: 'error',
                });
                this.dispatchEvent(evt);
                this.isLoading = false;
                this.isDuplicate = false;
                this.ExceptionMessage = false;
                this.LeadConverted = false;
                this.ErrorMessage = response;
                this.ErrormessageDisplay = true;
                if(this.ErrorMessage=='This lead matches an existing VIP Lead in the system. This cannot be converted.Please reach out to your manager'){
                    this.isVIPException =true;
                }
            }
           
        }).catch(error => {
            console.log('Error: ' + error.body.message);
        });
    }
    ClickException(event){
        this.isExceptionOpen = true;
    }
    handleChange(event){
        this.selectedValue = event.target.value;
        if(this.selectedValue =='Other'){
            this.disabledReason = false;
        }
    }
    updateOtherReason(event){
        this.otherReason = event.target.value;
    }
    updateOtherVIPReason(event){
        this.otherVIPReason = event.target.value;
    }
    sentforApprovalProcess(event){
        
        this.isLoading = true;
        if(this.otherReason != null && this.selectedValue != null){
        sentApproval({ 'LeadId': this.LeadId, 'OtherReason' :this.otherReason,'ExReason':this.selectedValue}).then(response => {
            this.isLoading = false;
            const evt = new ShowToastEvent({
                title: 'Success',
                message: 'Approval Submitted to manager Successfully',
                variant: 'success',
            });
            this.dispatchEvent(evt);
            this.isExceptionOpen = false;
            this.ExceptionMessage = true;
            this.ErrorMessage = '';
            this.ErrormessageDisplay = false;
            this.isDuplicate=false;
            
       }).catch(error => {
        this.isExceptionOpen = false;
        this.ErrorMessage = error.body.pageErrors[0].message;
        this.ErrormessageDisplay = true;
        this.isLoading = false;
        const evt = new ShowToastEvent({
            title: 'Error',
            message: error.body.pageErrors[0].message,
            variant: 'error',
        });
        this.dispatchEvent(evt);
           console.log('Error: ' +error.body.pageErrors[0].message);
       });
    }else{
        const evt = new ShowToastEvent({
            title: 'Error',
            message: 'Please complete required fields!',
            variant: 'error',
        });
        this.dispatchEvent(evt);
    }
    }

    handleConvertLead(event){
        this.isLoading = true;
        SearchBrokerLeadFlow({ 'LeadNumber':this.leadnumber}).then(response => {
            if(response != null && response != ''){
                
                const evt = new ShowToastEvent({
                    title: 'Error',
                    message: response,
                    variant: 'error',
                });
                this.dispatchEvent(evt);
                this.isLoading = false;
                this.isDuplicate = false;
                this.ExceptionMessage = false;
                this.LeadConverted = false;
                this.ErrorMessage = response;
                this.ErrormessageDisplay = true;
                if(this.ErrorMessage=='This lead matches an existing VIP Lead in the system. This cannot be converted.Please reach out to your manager'){
                    this.isVIPException =true;
                }
            }else{
                this.isLoading = false;
                this.LeadConverted = true;
                this.isDuplicate = false;
                this.ExceptionMessage = false;
                const evt = new ShowToastEvent({
                    title: 'Success',
                    message: 'Lead Converted Successfully',
                    variant: 'success',
                });
                this.dispatchEvent(evt);

            
            }
          
       }).catch(error => {
        this.isLoading = false;
           console.log('Error: ' + error.body.message);
       });
        
    }
    clickvip(event){
        this.isVIPExceptionOpen=true;
    }
    clickBroker(event){
        this.isBrokerException=true;
    }
    ClickVIPException(event){
        sentApproval({ 'LeadId': this.LeadId, 'OtherReason' :this.otherVIPReason,'ExReason':'VIP Reason Lead'}).then(response => {
            this.isLoading = false;
            const evt = new ShowToastEvent({
                title: 'Success',
                message: 'Approval Submitted to manager Successfully',
                variant: 'success',
            });
            this.dispatchEvent(evt);
            this.isExceptionOpen = false;
            this.isVIPExceptionOpen = false;
            this.ExceptionMessage = true;
            this.ErrorMessage = '';
            this.ErrormessageDisplay = false;
            this.isDuplicate=false;
            
       }).catch(error => {
        this.isExceptionOpen = false;
        this.ErrorMessage = error.body.pageErrors[0].message;
        this.ErrormessageDisplay = true;
        this.isLoading = false;
        const evt = new ShowToastEvent({
            title: 'Error',
            message: error.body.pageErrors[0].message,
            variant: 'error',
        });
        this.dispatchEvent(evt);
           console.log('Error: ' +error.body.pageErrors[0].message);
       });
    }
    ClickBrokerException(event){
        sentApproval({ 'LeadId': this.LeadId, 'OtherReason' :this.otherVIPReason,'ExReason':'Broker Reason Lead'}).then(response => {
            this.isLoading = false;
            const evt = new ShowToastEvent({
                title: 'Success',
                message: 'Approval Submitted to manager Successfully',
                variant: 'success',
            });
            this.dispatchEvent(evt);
            this.isExceptionOpen = false;
            this.isVIPExceptionOpen = false;
            this.isBrokerException = false;
            this.ExceptionMessage = true;
            this.ErrorMessage = '';
            this.ErrormessageDisplay = false;
            
       }).catch(error => {
        this.isExceptionOpen = false;
        this.ErrorMessage = error.body.pageErrors[0].message;
        this.ErrormessageDisplay = true;
        this.isLoading = false;
        const evt = new ShowToastEvent({
            title: 'Error',
            message: error.body.pageErrors[0].message,
            variant: 'error',
        });
        this.dispatchEvent(evt);
           console.log('Error: ' +error.body.pageErrors[0].message);
       });
    }
}