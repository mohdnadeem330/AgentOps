import { LightningElement, track, wire, api } from 'lwc';
import getCurrentUserDetails from '@salesforce/apex/RETL_ServiceRequestWizardController.getCurrentUserDetails';
export default class RetlTenantServiceRequestScreen extends LightningElement {
    @track activeTab = 'newRequests';
    @track selectedStore = null;
    @track error;
    @track contactId;
    @track selectedRequest = {}
    @api selectedAccountIdByStdUser
    @api selectedContactIdByStdUser;
    @api accessToken;
    requestSubmittingBy;
    orderId;
    showmyRequest = false;
    isMyRequestDetail = false;
    mainPage = true;
    submissionError = false;
    profileName;
    userData;
    showNavigation = false;
    get tabToShow() {
        return this.activeTab;
    }

    get showStoreSelector() {
        return !this.selectedStore;
    }

    connectedCallback() {
        this.display = `display-block`
        this.loadUserDetails();
    }



    async loadUserDetails() {
    try {
        const data = await getCurrentUserDetails({contactId:this.selectedContactIdByStdUser});
        this.userData = data;
        this.profileName = data.Profile.Name;
        if (this.profileName === 'Retail Contractor Profile' || this.profileName === 'DM Requestor Partner Login') {
            this.showNavigation = true;
        }
        if (data.UserType !== 'Standard') {
            this.contactId = data.ContactId;
        } else {
            this.contactId = this.selectedContactIdByStdUser;
        }
        if( this.selectedContactIdByStdUser){
            this.requestSubmittingBy = 'InternalUser'
        }
        else{
            this.requestSubmittingBy = 'CommunityUser'
        }
        this.loadProperties();

    } catch (error) {
        console.error('Error loading user details:', error);
        this.error = error;
    }
}


    handleTabChange(event) {
        this.activeTab = event.target.value;
        // Reset selected store when switching tabs
        if (this.activeTab === 'newRequests') {
            this.selectedStore = null;
        }
    }

    handleStoreSelected(event) {
        this.selectedStore = event.detail.storeName;
        this.orderId = event.detail.orderId;;

    }

    handleBackFromService() {
        // reset the state to show first screen again
        this.selectedStore = null;
    }

    showMyRequest(event) {
        this.activeTab = 'myRequests';
        //this.showStoreSelector = false;
        this.showmyRequest = true;
        this.selectedStore = null;
    }

    handleMyRequestEvent(event) {
        //this.display = event.detail.display ==='none'?'display-none':'display-block';
        this.mainPage = event.detail.display === 'none' ? false : true;
        this.isMyRequestDetail = event.detail.display === 'none' ? true : false;
        this.selectedRequest = event.detail.selectedRecord;
        if (this.mainPage) {
            this.activeTab = 'myRequests';
            console.log('showMyRequest');
            //this.showStoreSelector = false;
            this.showmyRequest = true;
            this.selectedStore = null;
        }

    }

    handleRecordCreationFailEvent(event) {
        this.submissionError = true;
        this.mainPage = false;
    }

    handleSubmitErrorEvent(event) {
        this.activeTab = 'newRequests';
        this.selectedStore = null;
        this.submissionError = false;
        this.mainPage = true;
    }
}