import { LightningElement, api, track, wire } from 'lwc';
import Images from "@salesforce/resourceUrl/RETLTenantPortalImages";
import getMyRequests from '@salesforce/apex/RETL_TenantRequestController.getMyRequests';
export default class Retl_TenantMyRequestScreen extends LightningElement {
    successimage = Images + '/Request/success.png';
    elementsimage = Images + '/Services/elements.png';
    calimage = Images + '/Services/cal.png';
    icon1image = Images + '/Request/icon1.png';
    icon2image = Images + '/Request/icon2.png';
    icon3image = Images + '/Request/icon3.png';
    icon4image = Images + '/Request/icon4.png';
    icon5image = Images + '/Request/icon5.png';
    icon6image = Images + '/Request/icon6.png';
    icon7image = Images + '/Request/icon7.png';
    icon8image = Images + '/Request/icon8.png';
    icon9image = Images + '/Request/icon9.png';
    icon11image = Images + '/Request/icon11.png';
    icon12image = Images + '/Request/icon12.png';
    icon13image = Images + '/Request/icon13.png';
    icon14image = Images + '/Request/icon14.png';
    icon15image = Images + '/Request/icon15.png';
    icon16image = Images + '/Request/icon16.png';
    icon17image = Images + '/Request/icon17.png';
    icon18image = Images + '/Request/icon18.png';
    icon19image = Images + '/Request/icon19.png';

    @api contactId;
    isLoading = false;
    showFirstScreen = true;
    showSecondScreen = false;
    search = true;
    @track files = [];

    @track requests = [];

    connectedCallback() {
        this.fetchMyRequests();
    }

    fetchMyRequests() {
        this.isLoading = true;
        getMyRequests({ contactId: this.contactId })
            .then(result => {
                // console.log('wiredCases', JSON.stringify(result));
                // Flatten additional info (Unit No)
                this.requests = result.map(c => {
                    const utcDate = new Date(c.CreatedDate);
                    return {
                        id: c.Id,
                        caseNumber: c.CaseNumber,
                        status: c.Status === 'Assigned' ? 'In Progress' : c.Status === 'New' ? 'Submitted':c.Status === 'Resolved_Closed'?'Resolved':  c.Status === 'Cancelled'? 'Rejected' : c.Status,
                        category: c.RETL_SR_Category__c,
                        subCategory: c.RETL_SR_Sub_Category__c,
                        serviceType: c.RETL_SR_Service_Type__c,
                        typeOfRequest: c.RETL_SR_Type_Of_Request__c,
                        caseComments: c.CaseComments__c,
                        // unitNo: (c.SR_Additional_Infos__r && c.SR_Additional_Infos__r.length > 0)
                        //     ? c.SR_Additional_Infos__r[0].RETL_Unit_No__c
                        //     : '',
                        unitNo : c.RETL_Store_Name__c ? c.RETL_Store_Name__c: '',
                        createdDate: (utcDate ? utcDate.toLocaleString() : ''),
                        iconsrc: `${c.Status === 'New' ? this.icon9image : c.Status === 'In Progress' ? this.icon19image : c.Status === 'Resolved_Closed' ? this.icon16image : c.Status === 'Rejected' ? icon17image : this.icon9image}`,
                        statusClass: `submitted-pill ${c.Status === 'In Progress' ? 'status-in-progress' : c.Status === 'new' ? 'status-submitted' : c.Status === 'Rejected' ? 'status-rejected' : c.Status === 'Resolved_Closed' ? 'status-resolved' : c.Status === 'Pending with Customer'?'status-pending-with-customer': c.Status === 'Cancelled'?'status-cancelled':''}`
                    };
                });
                this.isLoading = false;
                console.log('requests', JSON.stringify(this.requests));
            })
            .catch(error => {
                console.error('Error fetching my requests:', error);
                this.isLoading = false;
            });
    }


    
    showSecondScreenHandler() {
        this.showFirstScreen = false;
        this.showSecondScreen = true;
    }

    showFirstScreenHandler() {
        this.showFirstScreen = true;
        this.showSecondScreen = false;
         this.callParent('block');
    }



    // details to pass
    @track selectedRecord = {};
    @track normalSections = [];
    @track accordionSections = [];
    @track accordionItems = [];

    // click handler → move to second screen with detail
    handleRecordClick(event) {
        this.showSecondScreenHandler();

        // console.log('event', JSON.stringify(event));
        this.recordId = event.currentTarget.dataset.id;
        const record = this.requests.find(r => r.id === this.recordId);
        if (record) {
            if (record.category === 'Work Permit') {
                this.isWorkPermit = true;
            }
            this.selectedRecord = {
                caseId: record.id,
                caseNumber: record.caseNumber,
                category: record.category,
                subCategory: record.subCategory,
                status: record.status,
                serviceType: record.serviceType,
                typeOfRequest: record.typeOfRequest,
                createdDate: record.createdDate,
                selectedStore: record.unitNo,
                caseComments: record.caseComments,
                attachmentName: record.attachment,
                statusClass: record.statusClass,
                iconsrc: record.iconsrc
            };
            this.showFirstScreen = false;
            this.showSecondScreen = true;
        }
        this.callParent('none');
        //this.getCase(this.selectedRecord);
    }

    callParent(displayMsg){
       this.dispatchEvent(
            new CustomEvent('call', {
                detail: { display: displayMsg ,
                    selectedRecord:this.selectedRecord
                },
                bubbles: true,    //allow event to bubble up
                composed: true    //allow event to cross shadow DOM
            })
        );
    }





}