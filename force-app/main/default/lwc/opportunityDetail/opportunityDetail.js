import { api, LightningElement, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getOpportunityById from '@salesforce/apex/BrokerOpportunityController.getOpportunityById';
import getSalesOrderByOpportunity from '@salesforce/apex/BrokerOpportunityController.getSalesOrderByOpportunity';

export default class OpportunityDetail extends LightningElement {

    urlStateParameters = null;
    @track oppRecord;
    @track salesOrderRecord;
    @track array = [];
    @track gridData = [];
    @track showSpinner = false;
    @api oppRecordId;
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.urlStateParameters = currentPageReference.state;
        }
    }


    async connectedCallback() {
        this.showSpinner = true;

        
     
        await getOpportunityById({ opportunityId: this.oppRecordId })
            .then(result => {
              
                this.oppRecord = result;
            })
            .catch(error => {
                this.showSpinner = false;
            });

        await getSalesOrderByOpportunity({ opportunityId: this.oppRecordId })
            .then(result => {
                this.salesOrderRecord = result;
            })
            .catch(error => {
                this.showSpinner = false;
            });

          
        this.array = [
            {
                id: 1,
                column1Label: "Title:",
                column1Value: this.oppRecord.Account != null ? this.oppRecord.Account.Salutation : '',
                column2Label: "First Name:",
                column2Value: this.oppRecord.Account != null ? this.oppRecord.Account.FirstName : '',
                column3Label: "Last Name:",
                column3Value: this.oppRecord.Account != null ? this.oppRecord.Account.LastName : '',
            },
            {
                id: 1,
                column1Label: "Booking Type:",
                column1Value: this.oppRecord.BookingType__c,
                column2Label: "Agency Name:",
                column2Value: this.oppRecord.BrokerAgencyAccountName__c,
                column3Label: "Agent Name:",
                column3Value: this.oppRecord.BrokerAgentName__c,
            },
            {
                id: 1,
                column1Label: "Sales Manager:",
                column1Value: this.oppRecord.Owner.Name,
                column2Label: "Stage:",
                column2Value: this.oppRecord.StageName,
                column2Label: "Resident Status:",
                column2Value: this.oppRecord.ResidentStatus__c,
                column3Label: "Project:",
                column3Value: this.oppRecord.Project__c,
            }
        ];

        this.gridData = [
            {
                property: this.salesOrderRecord != null ? this.salesOrderRecord.ProjectName__c : '',

                unitCode: this.salesOrderRecord != null ? this.salesOrderRecord.UnitNumber__c : '',

                unitType: this.salesOrderRecord != null ? this.salesOrderRecord.UnitType__c : '',

                noofRooms: this.salesOrderRecord != null && this.salesOrderRecord.Unit__r != null  ? this.salesOrderRecord.Unit__r.TotalRooms__c : '',

                sellableArea: this.salesOrderRecord != null ? this.salesOrderRecord.UnitSaleableArea__c : '',

                sellingPrice: this.salesOrderRecord != null ? this.salesOrderRecord.UnitSellingPrice__c : '',

                totalDiscount: this.salesOrderRecord != null ? this.salesOrderRecord.Discount__c : '',

                payablePrice: this.salesOrderRecord != null ? this.salesOrderRecord.NetAmount__c : '',

                status: this.salesOrderRecord != null ? this.salesOrderRecord.Status__c : '',
            }];

            this.showSpinner = false;

    }
    /*array = [

        {
            id: 1,
            column1Label: "Title:",
            column1Value: "Test Test",
            column2Label: "First Name:",
            column2Value: "Test Test",
            column3Label: "Last Name:",
            column3Value: "Test Test",
        },
        {
            id: 1,
            column1Label: "Sale Type:",
            column1Value: "Test Test",
            column2Label: "Deal Type:",
            column2Value: "Test Test",
            column3Label: "Booking Type:",
            column3Value: "Test Test",
        },
        {
            id: 1,
            column1Label: "Agency Name:",
            column1Value: "Test Test",
            column2Label: "Agent Name:",
            column2Value: "Test Test",
            column3Label: "Sales Manager:",
            column3Value: "Test Test",
        },
        {
            id: 1,
            column1Label: "Stage:",
            column1Value: "Test Test",
            column2Label: "",
            column2Value: "",
            column3Label: "",
            column3Value: "",
        }


    ];*/


    /*gridData = [
        {
            property: "Test Test",

            unitCode: "Test Test",

            unitType: "Test Test",

            noofRooms: "Test Test",

            sellableArea: "Test Test",

            sellingPrice: "Test Test",

            totalDiscount: "Test Test",

            payablePrice: "Test Test",

            actions: ""
        },
        {
            property: "Test Test",

            unitCode: "Test Test",

            unitType: "Test Test",

            noofRooms: "Test Test",

            sellableArea: "Test Test",

            sellingPrice: "Test Test",

            totalDiscount: "Test Test",

            payablePrice: "Test Test",

            actions: ""
        },
        {
            property: "Test Test",

            unitCode: "Test Test",

            unitType: "Test Test",

            noofRooms: "Test Test",

            sellableArea: "Test Test",

            sellingPrice: "Test Test",

            totalDiscount: "Test Test",

            payablePrice: "Test Test",

            actions: ""
        }

    ];*/

    gridColumns = [
        {
            type: 'text',
            fieldName: 'property',
            label: 'Property',
            cellAttributes: { alignment: `center`,class: 'property-cell' /*important for reponsive */ }

        },
        {
            type: 'text',
            fieldName: 'unitCode',
            label: 'Unit Code',
            cellAttributes: { alignment: `center`,class: 'unit-code-cell' /*important for reponsive */ }
        },
        {
            type: 'text',
            fieldName: 'unitType',
            label: 'Unit Type',
            cellAttributes: { alignment: `center`,class: 'unit-type-cell' /*important for reponsive */ }
        },
        {
            type: 'text',
            fieldName: 'noofRooms',
            label: 'No Of Rooms',
            cellAttributes: {alignment: `center`, class: 'no-of-rooms-cell' /*important for reponsive */ }
        },
        {
            type: 'text',
            fieldName: 'sellableArea',
            label: 'Sellable Area',
            cellAttributes: { alignment: `center`,class: 'sellable-area-cell' /*important for reponsive */ }
        },
        {
            type: 'text',
            fieldName: 'sellingPrice',
            label: 'Selling Price',
            cellAttributes: {alignment: `center`, class: 'selling-price-cell' /*important for reponsive */ }
        },
        {
            type: 'text',
            fieldName: 'totalDiscount',
            label: 'Total Discount',
            cellAttributes: { alignment: `center`,class: 'total-discount-cell' /*important for reponsive */ }
        },
        {
            type: 'text',
            fieldName: 'payablePrice',
            label: 'Payable Price',
            cellAttributes: {alignment: `center`, class: 'payable-price-cell' /*important for reponsive */ }
        },
        {
            label: 'Status',
            initialWidth: 100,
            fieldName: 'status',
            cellAttributes: {
                iconName: { fieldName: 'statusIcon' },
                iconPosition: 'left',
            }

        }

    ];


    closeDetailPage(){
        document.dispatchEvent(new CustomEvent('tabsetdatafromcomponent', {detail : {showNavigationTab:true,currentStep:"manage-leads"}}));
       
        this.dispatchEvent(new CustomEvent('closedetailpage', {detail:{isOpen:false}}));
        
    }
    get gridDataSize(){
        return (this.gridData.length == 0 || this.salesOrderRecord == null);
    }
}