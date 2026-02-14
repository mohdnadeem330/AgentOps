import { LightningElement, track, wire } from 'lwc';
import resourcesPath from '@salesforce/resourceUrl/ALDARResources';
import getOpportunities from '@salesforce/apex/BrokerOpportunityController.getOpportunities';
import { NavigationMixin } from 'lightning/navigation';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import Project_FIELD from '@salesforce/schema/Opportunity.Project__c';
import Opportunity_OBJECT from '@salesforce/schema/Opportunity';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import ResidentStatus_FIELD from '@salesforce/schema/Opportunity.ResidentStatus__c';
import getAgencyName from "@salesforce/apex/ManageRequestController.getAgencyName";

export default class ManageOpportunities extends NavigationMixin(LightningElement) {

    //for Pagination 2 lines 
    currentPage = 1;
    pageSize = 10;
    //Filter js Start Here// 
	fillter = resourcesPath + '/ALDARResources/svg/fillter.svg';
    buttonClicked;
    @track cssClass = 'filters-items';
    @track iconClass = 'filters-title';
    @track iconName = ''; 
    handleToggleClick() {
        this.buttonClicked = !this.buttonClicked;
        this.iconClass = this.buttonClicked ? 'filters-title addbg' : 'filters-title';
        this.cssClass = this.buttonClicked ? 'filters-items showfillter' : 'filters-items';
        this.iconName = this.buttonClicked ? 'utility:check' : '';
    } 
    //Filter js End Here// 
    filterIcon = resourcesPath + "/ALDARResources/svg/FilterIcon.svg";
    ResetIcon = resourcesPath + "/ALDARResources/svg/ResetIcon.svg";
    agencyId;
    oppList;
    tableData = [];
    @track filteredData = [];
    @track newData = false;
    @track showDetailsPage = false;
    oppRecordId;
    @track showSpinner = false;
    stages = new Map([
        ["New", 'utility:answer'],
        ["Discussion In Progress", 'utility:anchor'],
        ["Proposal", 'utility:alert'],
        ["Meeting", 'utility:archive'],
        ["Closed Won", 'utility:attach'],
        ["Closed Lost", 'utility:assignment']
    ]);

    get options() {
        return [
            { label: '', value: '' },
            { label: 'New', value: 'New' },
            { label: 'Discussion In Progress', value: 'Discussion In Progress' },
            { label: 'Proposal', value: 'Proposal' },
            { label: 'Meeting', value: 'Meeting' },
            { label: 'Closed Won', value: 'Closed Won' },
            { label: 'Closed Lost', value: 'Closed Lost' },
        ];
    }

    @wire(getObjectInfo, { objectApiName: Opportunity_OBJECT })
    oppMetadata;

    @wire(getPicklistValues,
        {
            recordTypeId: '$oppMetadata.data.defaultRecordTypeId',
            fieldApiName: Project_FIELD
        }
    )
    projectPicklist;

    @wire(getPicklistValues,
        {
            recordTypeId: '$oppMetadata.data.defaultRecordTypeId',
            fieldApiName: ResidentStatus_FIELD
        }
    )
    residentStatusPicklist;

    @track oppNumFilter = '';
    @track textSearch = '';
    @track emailFilter = '';
    @track mobileFilter = '';
    @track agentFilter = '';
    @track smFilter = '';
    @track statusSearch = '';
    @track projectFilter = '';
    @track residentStatusFilter = '';

    handleChange(event) {

        var value = event.target.value;

        if (event.target.dataset.id === 'oppNumFilter') {
            this.oppNumFilter = value;
        } else if (event.target.dataset.id === 'textSearch') {
            this.textSearch = value;
        } else if (event.target.dataset.id === 'emailFilter') {
            this.emailFilter = value;
        } else if (event.target.dataset.id === 'mobileFilter') {
            this.mobileFilter = value;
        } else if (event.target.dataset.id === 'agentFilter') {
            this.agentFilter = value;
        } else if (event.target.dataset.id === 'smFilter') {
            this.smFilter = value;
        } else if (event.target.dataset.id === 'statusSearch') {
            this.statusSearch = value;
        } else if (event.target.dataset.id === 'residentStatusFilter') {
            this.residentStatusFilter = value;
        } else if (event.target.dataset.id === 'projectFilter') {
            this.projectFilter = value;
        }
    }

    resetAll() {
        this.filteredData = this.tableData;
        this.oppNumFilter = '';
        this.textSearch = '';
        this.emailFilter = '';
        this.mobileFilter = '';
        this.agentFilter = '';
        this.smFilter = '';
        this.statusSearch = '';
        this.residentStatusFilter = '';
        this.projectFilter = '';
    }

    updateSearch(event) {

        this.filteredData = this.tableData;

        this.gridExpandedRows = [];
        this.arr = [];
        this.toExpandRow = []

        var regex1 = new RegExp(this.oppNumFilter, 'i');
        var regex2 = new RegExp(this.textSearch, 'i');
        var regex3 = new RegExp(this.emailFilter, 'i');
        var regex4 = new RegExp(this.mobileFilter, 'i');
        var regex5 = new RegExp(this.agentFilter, 'i');
        var regex6 = new RegExp(this.smFilter, 'i');
        var regex7 = new RegExp(this.statusSearch, 'i');
        var regex8 = new RegExp(this.residentStatusFilter, 'i');
        var regex9 = new RegExp(this.projectFilter, 'i');

        if (this.textSearch != '') {
            this.filteredData = this.filteredData.filter(
                row => (regex2.test(row.firstName) || regex2.test(row.lastName) || regex2.test(row.firstName + ' ' + row.lastName))
            );
        }
        if (this.emailFilter != '') {
            this.filteredData = this.filteredData.filter(
                row => (regex3.test(row.email))
            );
        }
        if (this.mobileFilter != '') {
            this.filteredData = this.filteredData.filter(
                row => (regex4.test(row.mobile))
            );
        }
        if (this.agentFilter != '') {
            this.filteredData = this.filteredData.filter(
                row => (regex5.test(row.agentName))
            );
        }
        if (this.oppNumFilter != '') {
            this.filteredData = this.filteredData.filter(
                row => (regex1.test(row.opportunityNumber))
            );
        }
        if (this.smFilter != '') {
            this.filteredData = this.filteredData.filter(
                row => (regex6.test(row.salesManager))
            );
        }
        if (this.dateFilter != '') {
            this.filteredData = this.filteredData.filter(
                row => (regex7.test(row.status))
            );
        }
        if (this.projectFilter != '') {
            this.filteredData = this.filteredData.filter(
                row => (regex9.test(row.project))
            );
        }
        if (this.residentStatusFilter != '') {
            this.filteredData = this.filteredData.filter(
                row => (row.residentStatus == this.residentStatusFilter)
            );
        }
    }

    /*resetAll() {
        this.filteredData = this.tableData;
        this.statusSearch = '';
        this.textSearch = '';
    }*/
    /*updateSearch() {

        this.filteredData = this.tableData;

        let allSearchFields = this.template.querySelectorAll('.opportunityFilters');
        for (let j = 0; j < allSearchFields.length; j++) {
            console.log(allSearchFields[j].value);
            console.log(allSearchFields[j].dataset.id);
            if (allSearchFields[j].value != undefined && allSearchFields[j].value != '') {
                if (allSearchFields[j].dataset.id === 'statusSearch') {
                    this.statusSearch = allSearchFields[j].value;
                }
                if (allSearchFields[j].dataset.id === 'textSearch') {
                    this.textSearch = allSearchFields[j].value;
                }
            }

        }


        var regex = new RegExp(this.statusSearch, 'gi');
        this.filteredData = this.filteredData.filter(
            row => regex.test(row.status)
        );

        var regex = new RegExp(this.textSearch, 'gi');
        this.filteredData = this.filteredData.filter(
            row => (regex.test(row.opportunityNumber) || regex.test(row.firstName) || regex.test(row.lastName) || regex.test(row.saleType)
                || regex.test(row.dealType))
        );

        this.newData = true;

    }*/

    async connectedCallback() {

        await getAgencyName().then(result => {
            var data = [];
            data = result;
            this.agencyId                   = data.Id;
            //alert('AgentID'+this.agencyId); 
        }).catch(error => {
            // console.log('error' + JSON.stringify(error));
            //this.showSpinner = false;
        });

        this.showSpinner = true;
        setTimeout(() => {
            var el = this.template.querySelector('lightning-datatable');
            console.log(el)
        }, 3000);

        await getOpportunities({brokerAgentId : this.agencyId})
            .then(result => {
                this.oppList = result;
            })
            .catch(error => {
                console.log('getUserDetails error: ' + JSON.stringify(error));
                this.showSpinner = false;
            });

        this.oppList.forEach(element => {
            console.log(element);
            this.tableData.push({
                title: element.Account != null ? element.Account.Salutation : '',
                firstName: element.Account != null ? element.Account.FirstName : '',
                lastName: element.Account != null ? element.Account.LastName : '',
                email: element.Account != null ? element.Account.PersonEmail : '',
                mobile: element.Account != null ? element.Account.PersonMobilePhone : '',
                saleType: element.SalesTypefromLead__c,
                opportunityNumber: element.OpportunityNumber__c,
                leadNumber: element.LeadNumber__c,
                dealType: element.DealType__c,
                status: element.StageName,
                statusIcon: this.stages.get(element.StageName),
                actions: '',
                Id: element.Id,
                agentName: element.BrokerAgentName__c,
                salesManager: element.Owner.Name,
                residentStatus: element.ResidentStatus__c,
                project: element.Project__c
            })
        });

        this.filteredData = this.tableData;

        this.newData = true;
        this.showSpinner = false;
    }

    expandCollapseRowsRightSide(event) {

        if (event.detail.action.name == "Edit") {

            // this[NavigationMixin.Navigate]({
            //     type: 'comm__namedPage',
            //     attributes: {
            //         pageName: 'opportunity-detail'
            //     },
            //     state: {
            //         oppRecordId: event.detail.row.Id
            //     }
            // });

            document.dispatchEvent(new CustomEvent('tabsetdatafromcomponent', { detail: { showNavigationTab: false, currentStep: "manage-opportunities" } }));
            this.showDetailsPage = true;
            this.oppRecordId = event.detail.row.Id;


        }
    }

    handleCloseDetailPage(event) {
        document.dispatchEvent(new CustomEvent('tabsetdatafromcomponent', { detail: { showNavigationTab: true, currentStep: "manage-opportunities" } }));
        // to close modal set isModalOpen tarck value as false
        //this event has been fired from the modal component it self
        this.showDetailsPage = event.detail.isOpen;
    }

    tableColumns = [
        {
            type: 'text',
            fieldName: 'opportunityNumber',
            label: 'Opportunity Number',
            //initialWidth: 130,
        },
        {
            type: 'text',
            fieldName: 'title',
            label: 'Title',
            //initialWidth: 75,
        },
        {
            type: 'text',
            fieldName: 'firstName',
            //initialWidth:120,
            label: 'FirstName',
        },
        {
            type: 'text',
            fieldName: 'lastName',
            //initialWidth:120,
            label: 'Last Name',
        },
        {
            type: 'text',
            fieldName: 'email',
            initialWidth: 200,
            label: 'Email',
        },
        {
            type: 'text',
            fieldName: 'mobile',
            initialWidth: 150,
            label: 'Mobile',
        },
        {
            type: 'text',
            fieldName: 'leadNumber',
            label: 'Lead Number',
            //initialWidth: 130,
        },
        {
            type: 'text',
            fieldName: 'residentStatus',
           // initialWidth:140,
            label: 'Resident Status',
        },
        {
            type: 'text',
            fieldName: 'project',
            //initialWidth:140,
            label: 'Project',
        },
        {
            type: 'text',
            fieldName: 'agentName',
            //initialWidth:140,
            label: 'Agent Name',
        },
        {
            type: 'text',
            fieldName: 'salesManager',
            //initialWidth:140,
            label: 'Sales Manager',
        },
        {
            label: 'Status',
            //initialWidth: 185,
            fieldName: 'status',
            type: 'percent',
            cellAttributes: {
                iconName: { fieldName: 'statusIcon' },
                iconPosition: 'left',
            }

        }
        ,
        {

            label: 'Actions',
            fieldName: 'actions',
            initialWidth: 70,
            type: 'button',
            typeAttributes: {
                iconName: 'action:edit',

                name: 'Edit',
                title: 'Edit',
                disabled: false,
                value: 'Edit'

            },
            cellAttributes: {
                class: 'custom-table-icon view-icon',
                alignment: `left`
            }
        }

    ];

// Pagination : Calculate the total number of pages
get totalPages() {
    if (this.filteredData != undefined) {
        return Math.ceil(this.filteredData.length / this.pageSize);
    } else {
        return 0;
    }
}

// Pagination : Handle "Previous" button click
handlePrevious() {
    if (this.currentPage > 1) {
        this.currentPage--;
    }
    //this.filterData();
}

// Pagination : Handle "Next" button click
handleNext() {
    if (this.currentPage < this.totalPages) {
        this.currentPage++;
    }
    //this.filterData();
}

get filterData() {
    const startIndex = (this.currentPage - 1) * this.pageSize;
    const endIndex = startIndex + this.pageSize;
    return this.filteredData.slice(startIndex, endIndex);
}


    //utility:up open status
    //utility:up close status
    //
    /*tableData = [
        {
            title: 'Mr.',
            firstName: 'Gerge',
            lastName: 'D’souza',
            email: 'Useremail@gmail.com',
            mobile: '+971 50273537',
            country: 'United Arab Emirates',
            status: '',
            statusIcon: 'utility:up',
            actions: ''
        },
        {
            title: 'Mr.',
            firstName: 'Aaryan',
            lastName: 'Kapur',
            email: 'User223email@gmail.com',
            mobile: '+971 50273827',
            country: 'United Arab Emirates',
            status: '',
            statusIcon: 'utility:up',
            actions: ''
        },
        {
            title: 'Mr.',
            firstName: 'Luke',
            lastName: 'Shaw',
            email: 'Useremail009@gmail.com',
            mobile: '+971 502735721',
            country: 'United Arab Emirates',
            status: '',
            statusIcon: 'utility:down',
            actions: ''
        },
        {
            title: 'Mrs.',
            firstName: 'Tasneem',
            lastName: 'Khan',
            email: '12_Useremail@gmail.com',
            mobile: '+971 50273000',
            country: 'United Arab Emirates',
            status: '',
            statusIcon: 'utility:up',
            actions: ''

        },
        {
            title: 'Mrs.',
            firstName: 'Shivani',
            lastName: 'Gadkari',
            email: 'Usere__mail@gmail.com',
            mobile: '+971 54273537',
            country: 'United Arab Emirates',
            status: '',
            statusIcon: 'utility:up',
            actions: ''
        },
        {
            title: 'Mr.',
            firstName: 'test',
            lastName: 'test',
            email: 'test',
            mobile: 'test',
            country: 'United Arab Emirates',
            status: '',
            statusIcon: 'utility:down',
            actions: ''
        },
        {
            title: 'Mrs.',
            firstName: 'Navjyot',
            lastName: 'Singh',
            email: 'Useremail_2296@gmail.com',
            mobile: '+971 50273218',
            country: 'United Arab Emirates',
            status: '',
            statusIcon: 'utility:up',
            actions: ''
        },
        {
            title: 'Mr.',
            firstName: 'David',
            lastName: 'Malan',
            email: 'Unknownuseremail@gmail.com',
            mobile: '+971 50273438',
            country: 'United Arab Emirates',
            status: '',
            statusIcon: 'utility:down',
            actions: ''
        },
        {
            title: 'Mr.',
            firstName: 'Joel',
            lastName: 'Thomas',
            email: 'Useremail@gmail.com',
            mobile: '+971 54893537',
            country: 'United Arab Emirates',
            status: '',
            statusIcon: 'utility:up',
            actions: ''
        },

    ]*/
}