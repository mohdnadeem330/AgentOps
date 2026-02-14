// File: ecssUnitSearch.js
import { LightningElement, track,api,wire } from 'lwc';
import getUnits from '@salesforce/apex/ECSS_UnitSearchController.getFilteredUnits';
import getAllProjects from '@salesforce/apex/ECSS_UnitSearchController.getAllProjects';
import getAllZones from '@salesforce/apex/ECSS_UnitSearchController.getAllZones';
import getAllBuildings from '@salesforce/apex/ECSS_UnitSearchController.getAllBuildings';
import getAllUnitTypes from '@salesforce/apex/ECSS_UnitSearchController.getAllUnitTypes';
import getAllUnitAreas from '@salesforce/apex/ECSS_UnitSearchController.getAllUnitAreas';
import getAllViews from '@salesforce/apex/ECSS_UnitSearchController.getAllViews';
import getAllCommissionSource from '@salesforce/apex/ECSS_UnitSearchController.getAllCommissionSource';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import updateAssetStatus from '@salesforce/apex/ECSS_UnitSearchController.updateAssetStatus';
import getAllUnitUsages from '@salesforce/apex/ECSS_UnitSearchController.getAllUnitUsages';
import validateAndUpdateOpportunity from '@salesforce/apex/ECSS_UnitSearchController.validateAndUpdateOpportunity';
import addUnitsToQuote from '@salesforce/apex/ECSS_UnitSearchController.addUnitsToQuote';
import addUnitsToNewQuotes from '@salesforce/apex/ECSS_UnitSearchController.addUnitsToNewQuotes';
import updateNotifyCustomerFlag from '@salesforce/apex/ECSS_UnitSearchController.updateNotifyCustomerFlag';
import getUnitDetails from '@salesforce/apex/ECSS_UnitSearchController.getUnitDetails';
import getOfferDetails from '@salesforce/apex/ECSS_UnitSearchController.getOfferDetails';

import addUnitsWithQLIsForOffers from '@salesforce/apex/ECSS_UnitSearchController.addUnitsWithQLIsForOffers';
import { getRecord, getFieldValue  } from 'lightning/uiRecordApi';
import { getPicklistValuesByRecordType, getObjectInfo } from 'lightning/uiObjectInfoApi';
import RECORDTYPE_DEVNAME_FIELD from '@salesforce/schema/Opportunity.ECSS_RecordType_DevName__c';
import DOCUMENTS_CREATED from '@salesforce/schema/Opportunity.ECSS_Documents_Created__c';
import addUnitsToQuoteWithDetails from '@salesforce/apex/ECSS_UnitSearchController.addUnitsToQuoteWithDetails';


import addUnitToOpportunityProducts from '@salesforce/apex/ECSS_UnitSearchController.addUnitToOpportunityProducts';
import createAssetAndAddtoOpp from '@salesforce/apex/ECSS_UnitSearchController.createAssetAndAddtoOpp';
import addBulkUnitsToOppProducts from '@salesforce/apex/ECSS_UnitSearchController.addBulkUnitsToOppProducts';
import addUnitsToQuote_DontSplit from '@salesforce/apex/ECSS_UnitSearchController.addUnitsToQuote_DontSplit';

import createAccount from '@salesforce/apex/ECSS_UnitSearchController.createAccount';
import getAllMobileCountryCodes from '@salesforce/apex/ECSS_UnitSearchController.getAllMobileCountryCodes';
import checkDuplicateADMAsset from '@salesforce/apex/ECSS_UnitSearchController.checkDuplicateADMAsset';
import checkDuplicateDLDAsset from '@salesforce/apex/ECSS_UnitSearchController.checkDuplicateDLDAsset';
import INTERESTED_LOCATION_FIELD from '@salesforce/schema/Opportunity.ECSS_Interested_Location__c';
import SELLER_FIELD from '@salesforce/schema/Opportunity.Seller__c';
import SELLER_NAME_FIELD from '@salesforce/schema/Opportunity.Seller__r.Name';
import DEVELOPER_FIELD from '@salesforce/schema/Opportunity.ECSS_Developer__c';
import PROPERT_USAGE from '@salesforce/schema/Opportunity.PropertyUsage__c';
import ASSET_OBJECT from '@salesforce/schema/Asset';
import createCompanyAccount from '@salesforce/apex/ECSS_UnitSearchController.createCompanyAccount';
import createAssetAndAddtoOppOffPlan from '@salesforce/apex/ECSS_UnitSearchController.createAssetAndAddtoOppOffPlan';















export default class EcssUnitSearch extends LightningElement {
        
    @track searchTerm = '';
    @track selectedProject;
    @track selectedZone;
    @track selectedBuilding;
    @track selectedUnitType = '';
    @track selectedUnitArea = '';
    @track selectedFloorNumber = '';
    @track selectedBedrooms = '';
    @track selectedBaths = '';
    @track selectedView = '';
    @track selectedUnitUsage = '';


    @track isLoading = false;

    @track projectOptions = [];
    
    @track zoneOptions = [];
    @track buildingOptions = [];
    @track unitTypeOptions = [];
    @track unitTypeOptionsRt = [];
    @track unitAreaOptions = [];
    @track viewOptions = [];
        @track unitUsageOptions = [];
    @track commissionOptions = [];


    @track allUnits = [];
    @track pageSize = 10;
    @track currentPage = 1;
    @track selectedRowIds = [];
     @track hideCheckboxColumn = false;
    @track selectedCount = 0;

 @api recordId; 
  @track showSplitOfferModal = false;
@track selectedUnitIds = [];
@track selectedUnitDetails = [];
@track showConfirmationModal = false;
@track isCartLoading = false;

@track notifyCustomer = false;





    currentPageReference = null; 
    urlStateParameters = null;


@track taf=0;
@track sd=0;
@track rent=0;
@track adminFees=0;

@track showDetailsModal = false;


//Split Logic 
@track showOfferCountModal = false;
@track showOfferAssignmentModal = false;
@track offerCount = 1;
@track offers = [];
@track assetAssignments = {};


@track showOfferDetailsModal = false;
@track offerDetails = []; // array of { offerNum, taf, sd, rents: [] }


@track showDontSplitModal = false;
@track sharedSd = 0;
@track sharedTaf = 0;
@track sharedAdminFees = 0;
opportunity;
@track recTypeName;
@track documentsCreated=false;
@track secondaryMarket;
@track selectedComissionSource;
@track commission;
@track commission2;
@track commissionLabel='Commission %';
@track showCommission2;
@track unitPrice;
@track showCreateNewModal;
@track selectedNewComissionSource;
@track newCommission;
@track newCommissionLabel='Commission %';
@track newCommission2;
@track showCommission2New;
@track newUnitPrice;
@track selectedNewUnitType;
@track newUnitNumber;
@track newRemarks;

@track newOwnedById;
@track newOwnedByName;
@track showCreateAccountModal = false;
@track duplicateMessage = '';

// New account fields
@track accFirstName = '';
@track accLastName = '';
@track accEmiratesId = '';
@track accPassportNumber = '';
@track accEmail = '';
@track accMobileCountryCode = '';
@track accMobilePhone = '';
@track mobileCountryCodeOptions = [];

//new ADM Asset implementation
@track newADMBuildingNumber = '';
@track newADMPlotNumber = '';
@track newADMUnitNumber = '';
@track newADMSectorName = '';
@track newDLDBuildingNumber = '';
@track newDLDPlotNumber = '';
@track newDLDUnitNumber = '';
@track newDLDSectorName = '';
@track interestedLocation = '';
@track showDuplicateAssetModal = false;
@track duplicateAssetId;
@track duplicateAssetName;

@track sellerId;
@track sellerName;
@track hasSeller = false;
@track isOffPlan = false;
@track opportunityDeveloper;
@track newDeveloperId;
@track newDeveloperName;
@track hasDeveloper = false;
@track showCreateCompanyModal = false;
@track companyName = '';
@track companyTradeLicense ='';
@track assetRecordTypeId; 

@track newOwnedById;
@track newOwnedByName;
@track showCreateAccountModal = false;
@track duplicateMessage = '';

// New account fields
@track accFirstName = '';
@track accLastName = '';
@track accEmiratesId = '';
@track accPassportNumber = '';
@track accEmail = '';
@track accMobileCountryCode = '';
@track accMobilePhone = '';
@track mobileCountryCodeOptions = [];

//new ADM Asset implementation
@track newADMBuildingNumber = '';
@track newADMPlotNumber = '';
@track newADMUnitNumber = '';
@track newADMSectorName = '';
@track newDLDBuildingNumber = '';
@track newDLDPlotNumber = '';
@track newDLDUnitNumber = '';
@track newDLDSectorName = '';
@track interestedLocation = '';
@track showDuplicateAssetModal = false;
@track duplicateAssetId;
@track duplicateAssetName;

@track sellerId;
@track sellerName;
@track hasSeller = false;
@track isOffPlan = false;
@track opportunityDeveloper;
@track newDeveloperId;
@track newDeveloperName;
@track hasDeveloper = false;
@track showCreateCompanyModal = false;
@track companyName = '';
@track companyTradeLicense ='';






    // @wire(CurrentPageReference)
    // getPageReferenceParameters(currentPageReference) {
    //    if (currentPageReference) {
    //       console.log(currentPageReference);
    //       this.recordId = currentPageReference.attributes.recordId;
        
    //    }
    // }

    @wire(CurrentPageReference)
    capturePageRef(pageRef) {
        if (!this.recordId && pageRef?.attributes?.recordId) {
            this.recordId = pageRef.attributes.recordId;
            console.log('recordId from CurrentPageReference:', this.recordId);
        }
    }

connectedCallback() {
    console.log('connectedCallback - recordId:', this.recordId); 
     this.fetchAllFilterOptions();
     this.fetchCommissionSourceOptions();
     this.fetchMobileCountryCodeOptions(); 
            //this.fetchUnits();
}


    @wire(getRecord, { 
        recordId:'$recordId',
        fields: [DOCUMENTS_CREATED, RECORDTYPE_DEVNAME_FIELD, SELLER_FIELD, SELLER_NAME_FIELD, DEVELOPER_FIELD,INTERESTED_LOCATION_FIELD,PROPERT_USAGE]
    })
    wiredOpportunity({ error, data }) {
        if (data) {
            this.opportunity = data;
            this.recTypeName = getFieldValue(data, RECORDTYPE_DEVNAME_FIELD);
            this.opportunityDeveloper = getFieldValue(data, DEVELOPER_FIELD);
            this.isOffPlan = (this.recTypeName === 'ECSS_OffPlan');
            this.sellerId = getFieldValue(data, SELLER_FIELD) || null;
            this.sellerName = getFieldValue(data, SELLER_NAME_FIELD) || null;
            this.hasSeller = !!this.sellerId;
            this.interestedLocation = getFieldValue(data, INTERESTED_LOCATION_FIELD);


            if (this.hasSeller) {
                this.newOwnedById = this.sellerId;
                this.newOwnedByName = this.sellerName;
            }

            // Handle developer for OffPlan
            if (this.isOffPlan && this.opportunityDeveloper) {
                this.newDeveloperId = this.opportunityDeveloper;
                this.hasDeveloper = true;
            }

            this.secondaryMarket =
                this.recTypeName === 'ECSS_SecondaryMarket' ||
                this.recTypeName === 'ECSS_OffPlan';
                
            this.documentsCreated = getFieldValue(data, DOCUMENTS_CREATED);

            this.fetchUnits();
        }
        else if (error) {
            console.error('Error loading record via wire:', error);
        }
    }

    @wire(getObjectInfo, { objectApiName: ASSET_OBJECT })
    wiredAssetInfo({ data, error }) {
        if (data) {
            const targetName = 'Ecss Unit'; 

            const rtInfos = data.recordTypeInfos || {};
            const rtId = Object.keys(rtInfos).find(
                id => rtInfos[id]?.name === targetName
            );

            if (!rtId) {
                console.error(` Asset RecordType not found by name: ${targetName}`);
                this.assetRecordTypeId = undefined;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Configuration Error',
                        message: `Asset record type "${targetName}" not found or not assigned to this user.`,
                        variant: 'error'
                    })
                );
                return;
            }

            this.assetRecordTypeId = rtId;
            console.log(' assetRecordTypeId set:', this.assetRecordTypeId);
        } else if (error) {
            console.error('Error getObjectInfo(Asset):', error);
        }
    }
    @wire(getPicklistValuesByRecordType, {
    objectApiName: ASSET_OBJECT,
    recordTypeId: '$assetRecordTypeId'
    })
    wiredAssetPicklists({ data, error }) {
        if (data) {
            const vals = data.picklistFieldValues?.ECSS_Unit_Type__c?.values || [];
            this.unitTypeOptionsRt = vals.map(v => ({ label: v.label, value: v.value }));
        } else if (error) {
            console.error('Error getPicklistValuesByRecordType(Asset):', error);
        }
    }




   
    
    get documentsCreated() {
       return this.opportunity?.data?.fields?.ECSS_Documents_Created__c?.value;
    }
    
    fetchMobileCountryCodeOptions() {
        getAllMobileCountryCodes()
            .then(result => {
                this.mobileCountryCodeOptions = result;
            })
            .catch(error => {
                console.error('Error fetching mobile country codes:', error);
            });
    }
    fetchCommissionSourceOptions()
    {
        getAllCommissionSource().then(result=>{
             this.commissionOptions = result.map(v => ({ label: v, value: v }));
        });
    }
    fetchAllFilterOptions() {

        getAllProjects().then(result => {
            this.projectOptions = result.map(item => ({ label: item.projName, value: item.projId }));
        });
        getAllZones().then(result => {
            this.zoneOptions = result.map(item => ({ label: item.zoneName, value: item.zoneId }));
        });
        getAllBuildings().then(result => {
            this.buildingOptions = result.map(item => ({ label: item.buildingName, value: item.buildingId }));
        });
        getAllUnitTypes().then(data => {
            this.unitTypeOptions = data.map(v => ({ label: v, value: v }));
        });
        getAllUnitAreas().then(data => {
            this.unitAreaOptions = data.map(v => ({ label: v, value: v }));
        });
        getAllViews().then(data => {
            this.viewOptions = data.map(v => ({ label: v, value: v }));
        });
        getAllUnitUsages().then(data => {
    this.unitUsageOptions = data.map(v => ({ label: v, value: v }));
});
    }

    fetchUnits() {
                    const bathsInt = this.selectedBaths ? parseInt(this.selectedBaths, 10) : null;

        this.isLoading = true;
        getUnits({
            projectId: this.selectedProject,
            zoneId: this.selectedZone,
            buildingId: this.selectedBuilding,
            unitType: this.selectedUnitType,
            unitArea: this.selectedUnitArea,
            floorNumber: this.selectedFloorNumber,
            bedrooms: this.selectedBedrooms,
            baths: bathsInt,
            view: this.selectedView,
            searchKey: this.searchTerm,
             unitUsage: this.selectedUnitUsage,
             recordTypeDevName: this.recTypeName,
            developerId: this.isOffPlan && this.opportunityDeveloper ? this.opportunityDeveloper : null
        })
        .then(data => {
            this.allUnits = data.map(unit => ({
                ...unit,
                unitLink: `/lightning/r/Asset/${unit.Id}/view`,
                projectLink: unit.ECSS_Project__c ? `/lightning/r/${unit.ECSS_Project__c}/view` : '',
                projectName: unit.ECSS_Project__r?.Name || '',
                zoneLink: unit.ECSS_Zone__c ? `/lightning/r/${unit.ECSS_Zone__c}/view` : '',
                zoneName: unit.ECSS_Zone__r?.Name || '',
                buildingLink: unit.ECSS_Building_Section__c ? `/lightning/r/${unit.ECSS_Building_Section__c}/view` : '',
                buildingName: unit.ECSS_Building_Section__r?.Name || '',
                    unitUsage: unit.ECSS_Unit_Usage__c || '',
                    UnitPrice : this.secondaryMarket? unit.ECSS_Selling_Price__c: null

            }));
            console.log('Inside Fetch Units: '+ data);
        })
        .catch(error => {
            console.error('Error retrieving units:', error);
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    handleSearchTermChange(event) {
        this.searchTerm = event.target.value;
    }

    handleFilterChange(event) {
        const label = event.target.label;
        const value = event.detail.value;

        switch (label) {
            case 'Unit Type': this.selectedUnitType = value; break;
            case 'Unit Area': this.selectedUnitArea = value; break;
            case 'Floor Number': this.selectedFloorNumber = value; break;
            case 'Bedrooms': this.selectedBedrooms = value; break;
            case 'Bathrooms': this.selectedBaths = value; break;
            case 'View': this.selectedView = value; break;
        }
    }

    handleProjectChange(event) {
        this.selectedProject = event.detail.value;
    }

    handleZoneChange(event) {
        this.selectedZone = event.detail.value;
    }

    handleBuildingChange(event) {
        this.selectedBuilding = event.detail.value;
    }

    handleSearchClick() {
        this.currentPage = 1;
        this.fetchUnits();
    }
/*
addToCurrentOpportunity(unitIds) {
    this.isCartLoading = true;

    addUnitsToOpportunity({ unitIds: unitIds, opportunityId: this.recordId })
      
        .then(() => {
            this.template.querySelector('lightning-datatable').selectedRows = [];
            this.selectedCount = 0;
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: 'Units added to current opportunity and status updated.',
                variant: 'success'
            }));
        })
        .catch(error => {
            console.error('Error:', error);
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Failed to add units or update statuses.',
                variant: 'error'
            }));
        })
        .finally(() => {
            this.isCartLoading = false;
        });
}

*/
addToQuote(unitIds) {
    this.isCartLoading = true;
    return addUnitsToQuote({ unitIds: unitIds, opportunityId: this.recordId }) // <- ADD RETURN
        .then(() => {
            this.template.querySelector('lightning-datatable').selectedRows = [];
            this.selectedCount = 0;
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: 'Units added to quote and lines created.',
                variant: 'success'
            }));
        })
        .catch(error => {
            console.error('Error:', error);
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Failed to add units to quote.',
                variant: 'error'
            }));
        })
        .finally(() => {
            this.isCartLoading = false;
        });
}


createOpportunitiesPerUnit(unitIds) {
    this.isCartLoading = true;
    console.log('Parent Id ' + this.recordId);


    return addUnitsToNewQuotes({ unitIds: unitIds, parentOpportunityId: this.recordId }) // <- ADD RETURN
        .then(() => {
            this.template.querySelector('lightning-datatable').selectedRows = [];
            this.selectedCount = 0;
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: 'Separate opportunities created and statuses updated.',
                variant: 'success'
            }));
        })
        .catch(error => {
            console.error('Split Error:', error);
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Failed to create opportunities or update statuses.',
                variant: 'error'
            }));
        })
        .finally(() => {
            this.isCartLoading = false;
        });
}


handleCartClick() {
    const datatable = this.template.querySelector('lightning-datatable');
    const selectedRows = datatable.getSelectedRows();
    const propertyUsage = this.opportunity?.data?.fields?.PropertyUsage__c?.value;


    if (selectedRows.length === 0) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Missing Data',
            message: 'Please ensure at least one unit is selected.',
            variant: 'error'
        }));
        return;
    }

    const unitIds = selectedRows.map(row => row.Id);
    const projectIds = new Set();
    const usageTypes = new Set();
    const buildingIds = new Set();
    const ownerIds = new Set();
    let invalidUsage = false;

    for (const row of selectedRows) {
        projectIds.add(row.ECSS_Project__c || 'NO_PROJECT');
        if(propertyUsage!=null)
        {
           if(!propertyUsage.includes(row.ECSS_Unit_Usage__c))
            {
                invalidUsage= true;
            } 
        }
        usageTypes.add(row.ECSS_Unit_Usage__c || 'NO_USAGE');
        buildingIds.add(row.ECSS_Building_Section__c || 'NO_BUILDING');
        ownerIds.add(row.OwnerId || 'NO_OWNER');
    }

    if (projectIds.size > 1) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Invalid Selection',
            message: 'Please select units from the same project only.',
            variant: 'error'
        }));
        return;
    }

    if (usageTypes.size > 1) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Invalid Selection',
            message: 'Please select units with the same Unit Usage only.',
            variant: 'error'
        }));
        return;
    }

    if(invalidUsage){
         this.dispatchEvent(new ShowToastEvent({
            title: 'Invalid Selection',
            message: 'Please select units with the Unit Usage same on Opportunity.',
            variant: 'error'
        }));
        return;
    }
    
    if (buildingIds.size > 1) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Invalid Selection',
            message: 'Please select units from the same building only.',
            variant: 'error'
        }));
        return;
    }

    if (ownerIds.size > 1) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Invalid Selection',
            message: 'Please select units that belong to the same owner/landlord only.',
            variant: 'error'
        }));
        return;
    }

    validateAndUpdateOpportunity({ opportunityId: this.recordId, unitIds: unitIds })
        .then(() => {
            this.selectedUnitIds = unitIds;
            this.selectedUnitDetails = selectedRows.map(row => ({
                Id: row.Id,
                Name: row.Name,
                UnitPrice : row.UnitPrice
            }));
            console.log('this.opportunity:',this.opportunity);
            if (unitIds.length === 1) {
                this.showConfirmationModal = true;
                if(this.secondaryMarket)
                {
                    this.unitPrice = this.selectedUnitDetails[0].UnitPrice;
                  
                }
            } else if( unitIds.length > 1 && !this.secondaryMarket) {
                this.showSplitOfferModal = true;
            }
            else if(unitIds.length>1 && this.secondaryMarket)
            {   
                    
                    this.handleSplitNo();
                
            }
        })
        .catch(error => {
            console.log("error",error);
            this.dispatchEvent(new ShowToastEvent({
                title: 'Validation Error',
                message: error.body?.message || 'An error occurred during validation.',
                variant: 'error'
            }));
        });
}


updateNotifyCustomerThen(callback) {
    this.isCartLoading = true;
    console.log('ߓ䠃alling updateNotifyCustomerFlag from updateNotifyCustomerThen...');
    console.log('Opportunity ID:', this.recordId);
    console.log('Notify Customer checked:', this.notifyCustomer);

    updateNotifyCustomerFlag({
        opportunityId: this.recordId,
        notifyCustomer: this.notifyCustomer
    })
    .then(() => {
        console.log('✅ NotifyCustomer updated successfully. Proceeding to callback.');
        callback();
    })
    .catch(error => {
        console.error(' Error updating NotifyCustomer:', error);
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: 'Failed to update notification flag before proceeding.',
                variant: 'error'
            })
        );
    });
}

updateNotifyCustomerFlagAfterAction() {
    console.log('ߓ䠃alling updateNotifyCustomerFlag...');
    console.log('Opportunity ID:', this.recordId);
    console.log('Notify Customer checked:', this.notifyCustomer);

    updateNotifyCustomerFlag({
        opportunityId: this.recordId,
        notifyCustomer: this.notifyCustomer
    })
    .then(() => {
        console.log('✅ updateNotifyCustomerFlag call succeeded');
        
    })
    .catch(error => {
        console.error('Error in updateNotifyCustomerFlag:', error);
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: 'Failed to update opportunity status after quote update.',
                variant: 'error'
            })
        );
    });
}



// handleSplitYes() {
//     this.showSplitOfferModal = false;
//     this.createOpportunitiesPerUnit(this.selectedUnitIds).then(() => {
//         this.updateNotifyCustomerFlagAfterAction();
//     });
// }

handleSplitYes() {
    this.showSplitOfferModal = false;
    this.showOfferCountModal = true;
}



    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedCount = selectedRows.length;
    }

    get filteredUnits() {
        return this.allUnits;
    }

    get paginatedUnits() {
        const start = (this.currentPage - 1) * this.pageSize;
        return this.filteredUnits.slice(start, start + this.pageSize);
    }

    get isFirstPage() {
        return this.currentPage === 1;
    }

    get isLastPage() {
        return this.currentPage >= Math.ceil(this.filteredUnits.length / this.pageSize);
    }
    get ownerFieldLabel() {
    return this.isOffPlan ? 'Developer' : 'Owned By';
    }

    get showCommissionFields() {
        return !this.isOffPlan && this.secondaryMarket;
    }
    get showDLDFields() {
        return this.interestedLocation === 'Dubai';
    }



    handlePreviousPage() {
        if (!this.isFirstPage) {
            this.currentPage--;
        }
    }

    handleNextPage() {
        if (!this.isLastPage) {
            this.currentPage++;
        }
    }

    clearProject() {
        this.selectedProject = null;
    }

    clearZone() {
        this.selectedZone = null;
    }

    clearBuilding() {
        this.selectedBuilding = null;
    }

    clearUnitType() {
    this.selectedUnitType = '';
}
clearUnitArea() {
    this.selectedUnitArea = '';
}
clearUsage() {
    this.selectedUnitUsage = '';
}
clearView() {
    this.selectedView = '';
}
handleCloseModal() {
    this.showSplitOfferModal = false;
        this.showConfirmationModal = false;

}

handleConfirmSingle() {
    this.showConfirmationModal = false;
    const assetId = this.selectedUnitIds[0];

    this.isCartLoading = true; 
    if(this.secondaryMarket){
        this.isCartLoading = false; 
        this.showDetailsModal = true;
        
    } 
    else
    {
    getUnitDetails({ assetId })
        .then(data => {
           this.taf = Number(data.taf) || 0;
        this.sd =  0;
        this.rent = Number(data.rent) || 0;
        })
        .catch(error => {
            console.error('Error fetching unit details', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Failed to fetch unit details.',
                    variant: 'error'
                })
            );
        })
        .finally(() => {
            this.isCartLoading = false; 
                this.showDetailsModal = true; 

        });
    }
    
}




    get noResultsFound() {
        return !this.isLoading && this.filteredUnits.length === 0;
    }

    handleUsageChange(event) {
    this.selectedUnitUsage = event.detail.value;
}

handleNotifyCustomerChange(event) {
    this.notifyCustomer = event.target.checked;
}


// ----------------------Details Confrim Section -------------------------------------------
handleTafChange(event) {
    this.taf = parseFloat(event.target.value) || 0;
}

handleAdminFeesChange(event) {
    this.adminFees = parseFloat(event.target.value) || 0;
}
handleSdChange(event) {
    const val = event.target.value;
    this.sd = val === '' ? '' : Number(val);
}

handleSingleRentChange(event) {
    this.rent = parseFloat(event.target.value) || 0;
}
handleCommissionChange(event) {
    this.commission = parseFloat(event.target.value);
}
handleCommission2Change(event) {
    this.commission2 = parseFloat(event.target.value);
}
handleCommissionSourceChange(event) {
        this.selectedComissionSource = event.detail.value;
        if(this.selectedComissionSource ==='Both')
        {
            this.showCommission2 = true;
            this.commissionLabel ='Seller Commission %';
        }
        else{
            this.showCommission2 = false;
            this.commissionLabel='Commission %';
        }

        console.log('Selected:', this.selectedComissionSource);
}
handlePriceChange(event) {
    this.unitPrice = parseFloat(event.target.value);
}
handleDetailsConfirm() {
    if (!this.recordId) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Missing Opportunity',
                message: 'Could not find the Opportunity Id (recordId).',
                variant: 'error'
            })
        );
        return;
    }

    // Clean up: only handle selected units
    const cleanUnitIds = [...(this.selectedUnitIds || [])];

    if (cleanUnitIds.length === 0) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: 'No unit selected. Please reopen and confirm again.',
                variant: 'error'
            })
        );
        return;
    }
    if(this.secondaryMarket && (!this.commission || !this.selectedComissionSource || !this.unitPrice) || (this.selectedComissionSource==='Both' && (!this.commission || !this.commission2)))
    {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please fill required fields',
                    variant: 'error'
                })
            );
            return;
            
    }

    this.isCartLoading = true;
    if(this.secondaryMarket)
    {
        
        addUnitToOpportunityProducts({
        unitIds: cleanUnitIds,
        opportunityId: this.recordId,
        commission: Number(this.commission),
        commission2 : this.commission2? Number(this.commission2):null,
        commissionSource: this.selectedComissionSource ,
        unitPrice: Number(this.unitPrice)
    })
        .then((data) => {
            this.commission = Number(data?.commission) || 0;
            this.commission2 = Number(data?.commission2) || 0;
            this.selectedComissionSource   = Number(data?.commissionSource) || 0;
            this.unitPrice  = Number(data?.unitPrice) || 0;
            this.showDetailsModal = false;

            //return updateAssetStatus({ unitIds: cleanUnitIds });
        })
        .then(() => this.updateNotifyCustomerFlagAfterAction())
        .then(() => this.fetchUnits())
        .then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Opportunity Product created.',
                    variant: 'success'
                })
            );
                setTimeout(() => {
                window.location.reload();
                }, 500);
        })
        .catch((error) => {
            console.error('Error in handleDetailsConfirm:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message:
                        error?.body?.message ||
                        'Failed to complete unit update or quote process.',
                    variant: 'error'
                })
            );
        })
        .finally(() => {
            this.isCartLoading = false;
        });
    }
    else
    {
    addUnitsToQuoteWithDetails({
        unitIds: cleanUnitIds,
        opportunityId: this.recordId,
        rent: Number(this.rent) || 0,
        sd: Number(this.sd) || 0,
        taf: Number(this.taf) || 0,
        adminFees: Number(this.adminFees) || 0
    })
        .then((data) => {
            this.rent = Number(data?.rent) || 0;
            this.sd   = Number(data?.sd) || 0;
            this.taf  = Number(data?.taf) || 0;
            this.adminFees = Number(this.adminFees) || 0;
            this.showDetailsModal = false;

            return updateAssetStatus({ unitIds: cleanUnitIds });
        })
        .then(() => this.updateNotifyCustomerFlagAfterAction())
        .then(() => this.fetchUnits())
        .then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Unit details updated, Quote created, and status marked Under Offer.',
                    variant: 'success'
                })
            );
                setTimeout(() => {
                window.location.reload();
                }, 500);
        })
        .catch((error) => {
            console.error(' Error in handleDetailsConfirm:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message:
                        error?.body?.message ||
                        'Failed to complete unit update or quote process.',
                    variant: 'error'
                })
            );
        })
        .finally(() => {
            this.isCartLoading = false;
        });
    }
}


handleDetailsCancel(){
    this.showDetailsModal = false;
}

//---------------------- Split logic ------------------------------------------------

handleOfferCountChange(event) {
    this.offerCount = parseInt(event.target.value, 10);
}

closeOfferCountModal() {
    this.showOfferCountModal = false;
}
 confirmOfferCount() {
    const assetCount = this.selectedUnitDetails?.length || 0;

    if (assetCount < 2) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Invalid Selection',
                message: 'You must select at least 2 assets to split into offers.',
                variant: 'error'
            })
        );
        return;
    }

    if (this.offerCount < 2) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Invalid Number',
                message: 'You must create at least 2 offers.',
                variant: 'error'
            })
        );
        return;
    }

    if (this.offerCount > assetCount) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Invalid Number',
                message: `Number of offers (${this.offerCount}) cannot exceed number of selected assets (${assetCount}).`,
                variant: 'error'
            })
        );
        return;
    }

    this.offers = Array.from({ length: this.offerCount }, (_, i) => i + 1);
    this.assetAssignments = {};
    this.showOfferCountModal = false;
    this.showOfferAssignmentModal = true;
}


get offerOptions() {
    return this.offers.map(num => ({ label: `Offer ${num}`, value: num.toString() }));
}

getAssignmentValue(unitId) {
    return this.assetAssignments[unitId] || null;
}

handleAssignmentChange(event) {
    const unitId = event.target.dataset.id;
    const offerNum = event.detail.value;

    this.assetAssignments = {
        ...this.assetAssignments,
        [unitId]: offerNum
    };
}

closeOfferAssignmentModal() {
    this.showOfferAssignmentModal = false;
}
confirmAssignments() {
    const grouped = {};
    for (const [assetId, offerNum] of Object.entries(this.assetAssignments)) {
        if (!grouped[offerNum]) grouped[offerNum] = [];
        grouped[offerNum].push(assetId);
    }

    this.isCartLoading = true;

    addUnitsToNewQuotes({
        parentOpportunityId: this.recordId,
        offerAssignments: grouped
    })
    .then(result => {
        this.offerQuoteMap = result;
    console.log('offer Map ', this.offerQuoteMap);

        this.isCartLoading = false;
        this.showOfferAssignmentModal = false;

        // Fetch offer details
        return getOfferDetails({ offerAssetMap: grouped });
    })

           

    .then(result => {
        this.offerDetails = result.map(offer => ({
            offerNum: offer.offerNum,
            title: offer.title,
            taf: offer.taf || 0,
            sd: offer.sd || 0,
            adminFees: offer.adminFees || 0,
            rents: Array.isArray(offer.rents) ? offer.rents : []
        }));

          console.log('offer Map ', this.offerQuoteMap);
        this.showOfferDetailsModal = true;
    })
    .catch(error => {
        this.isCartLoading = false;
 this.dispatchEvent(
        new ShowToastEvent({
            title: 'Validation Error',
            message: error.body?.message || 'Parent Opportunity still has Quotes. Please delete them first.',
            variant: 'error'
        })
    );    });
}


fetchOfferDetails() {
    getOfferDetails({ assetIds: this.selectedUnitIds })
        .then(result => {
            console.log('ߔ�aw Apex result:', JSON.stringify(result));

            if (!Array.isArray(result)) {
                console.error(' Expected an array but got:', result);
                return;
            }

            this.offerDetails = result.map((offer, index) => {
                console.log(` Offer ${index + 1}:`, JSON.stringify(offer));

                return {
                    offerNum: index + 1,
                    title: `Offer ${index + 1}`,
                    taf: offer.taf || 0,
                    sd: offer.sd || 0,
                    rents: Array.isArray(offer.rents) ? offer.rents : []
                };
            });

            console.log(' Final offerDetails set in JS:', JSON.stringify(this.offerDetails));
            this.showOfferDetailsModal = true;
        })
        .catch(error => {
            console.error(' Error fetching offer details:', error);
        });
}




get unitsWithAssignments() {
    if (!this.selectedUnitDetails || !Array.isArray(this.selectedUnitDetails)) {
        return [];
    }

    return this.selectedUnitDetails.map(unit => {
        let assignmentValue = this.assetAssignments
            ? this.assetAssignments[unit.Id]
            : null;

        return {
            ...unit,
            assignmentValue
        };
    });
}
handleOfferChange(event) {
    const offerNum = parseInt(event.target.dataset.offernum, 10);
    const field = event.target.dataset.field;
    const value = parseFloat(event.target.value);

    this.offerDetails = this.offerDetails.map(offer => {
        if (offer.offerNum === offerNum) {
            return { ...offer, [field]: value };
        }
        return offer;
    });
}


handleRentChange(event) {
    const offerNum = parseInt(event.target.dataset.offernum, 10);
    const index = parseInt(event.target.dataset.index, 10);
    const value = parseFloat(event.target.value);

    this.offerDetails = this.offerDetails.map(offer => {
        if (offer.offerNum === offerNum) {
            let updatedRents = [...offer.rents];
            updatedRents[index] = { ...updatedRents[index], rent: value };
            return { ...offer, rents: updatedRents };
        }
        return offer;
    });
}





confirmOfferDetailsbuildOfferAssignmentsMap() {
    const grouped = {};

    for (const [assetId, offerNum] of Object.entries(this.assetAssignments)) {
        if (!grouped[offerNum]) {
            grouped[offerNum] = [];
        }
        grouped[offerNum].push(assetId);
    }

    return grouped;
}



confirmOfferDetails() {
    this.isCartLoading = true;

    addUnitsWithQLIsForOffers({
        parentOpportunityId: this.recordId,
        offerQuoteMap: this.offerQuoteMap,  
        offers: this.offerDetails
    })
    .then(result => {
        console.log(' QLIs returned from Apex:', JSON.stringify(result, null, 2));

        const assetIds = [];
        this.offerDetails.forEach(offer => {
            if (offer.rents) {
                offer.rents.forEach(r => {
                    if (r.assetId) assetIds.push(r.assetId);
                });
            }
        });

        if (assetIds.length > 0) {
            return updateAssetStatus({ unitIds: assetIds });
        }
    })
    .then(() => {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: `Offer details confirmed. Quote Line Items created and Assets marked Under Offer.`,
                variant: 'success'
            })
        );
        this.closeOfferDetailsModal();
    })
    .catch(error => {
        console.error(' Error creating QLIs or updating assets:', error);
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: 'Failed to confirm offers or update asset statuses.',
                variant: 'error'
            })
        );
    })

    .then(() => {
        return this.updateNotifyCustomerFlagAfterAction();
    })

    .finally(() => {
        this.isCartLoading = false;
    });
}


closeOfferDetailsModal() {
    this.showOfferDetailsModal = false;
    this.offerDetails = [];
}



    get columns() {
        return [
            { label: 'Unit Name', fieldName: 'unitLink', type: 'url', typeAttributes: { label: { fieldName: 'Name' }, target: '_blank' }, initialWidth: 150 },
            { label: 'External ID', fieldName: 'ExternalIdentifier', type: 'text', initialWidth: 150  },
            { label: 'Unit Type', fieldName: 'ECSS_Unit_Type__c', type: 'text' , initialWidth: 150 },
            { label: 'Floor', fieldName: 'ECSS_Floor_Number__c', type: 'text' , initialWidth: 150 },
            { label: 'Area', fieldName: 'ECSS_Unit_Area__c', type: 'text' , initialWidth: 150 },
            { label: 'Beds', fieldName: 'ECSS_Number_of_Bedrooms__c', type: 'text', initialWidth: 150  },
            { label: 'Baths', fieldName: 'ECSS_Number_of_Baths__c', type: 'text', initialWidth: 150  },
            { label: 'View', fieldName: 'ECSS_View__c', type: 'text' , initialWidth: 150 },
            { label: 'Project', fieldName: 'projectLink', type: 'url', typeAttributes: { label: { fieldName: 'projectName' }, target: '_blank' } , initialWidth: 150 },
            { label: 'Zone', fieldName: 'zoneLink', type: 'url', typeAttributes: { label: { fieldName: 'zoneName' }, target: '_blank' } , initialWidth: 150 },
            { label: 'Building', fieldName: 'buildingLink', type: 'url', typeAttributes: { label: { fieldName: 'buildingName' }, target: '_blank' } , initialWidth: 150 },
            { label: 'Unit Usage', fieldName: 'ECSS_Unit_Usage__c', type: 'text' , initialWidth: 150 },

            
        ];
    }


//---------------------------Dont split logic-------------------------------------

handleDontSplitFieldChange(event) {
    const unitId = event.target.dataset.id;
    const field = event.target.dataset.field;
    const value = parseFloat(event.target.value) || 0;

    this.selectedUnitDetailsFull = this.selectedUnitDetailsFull.map(unit =>
        unit.Id === unitId ? { ...unit, [field]: value } : unit
    );
}
/*
handleUnitCommPicklistChange(event) {
        const index = event.target.dataset.index;
        const value = event.detail.value;
        console.log('source',value);
       
        // Update the correct record
        this.selectedUnitDetailsFull = this.selectedUnitDetailsFull.map((item, i) =>
            i === parseInt(index) ? { ...item, CommissionSource: value } : item
        );
        
        console.log('Updated builtDetails:', JSON.stringify(this.selectedUnitDetailsFull, null, 2));
}
handleUnitCommissionChange(event)
{
     const index = event.target.dataset.index;
        const value = event.detail.value;
         this.selectedUnitDetailsFull = this.selectedUnitDetailsFull.map((item, i) =>
            i === parseInt(index) ? { ...item, Commission: value } : item
        );

}
handleUnitCommission2Change(event)
{
     const index = event.target.dataset.index;
        const value = event.detail.value;
         this.selectedUnitDetailsFull = this.selectedUnitDetailsFull.map((item, i) =>
            i === parseInt(index) ? { ...item, Commission2: value } : item
        );

}*/
handleUnitPriceChange(event)
{
     const index = event.target.dataset.index;
        const value = event.detail.value;
         this.selectedUnitDetailsFull = this.selectedUnitDetailsFull.map((item, i) =>
            i === parseInt(index) ? { ...item, UnitPrice: value } : item
        );

}

handleSplitNo() {
    this.showSplitOfferModal = false;

    if (!this.selectedUnitIds || this.selectedUnitIds.length === 0) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'No Units Selected',
                message: 'Please select at least one unit.',
                variant: 'error'
            })
        );
        return;
    }

    this.isCartLoading = true;
    if(this.secondaryMarket)
    {
            const promises = this.selectedUnitIds.map(assetId =>
        
        getUnitDetails({ assetId })
            
            );
        Promise.all(promises)
        .then(results => {
            const builtDetails = results.map((res, index) => ({
                Id: this.selectedUnitIds[index],
                Name: this.selectedUnitDetails?.[index]?.Name || '',
                /*Commission: null,
                Commission2: null,
                CommissionSource :null,
                CommissionLabel : 'Commission %',
                ShowCommission2 : false,*/
                UnitPrice: this.selectedUnitDetails?.[index]?.UnitPrice || '',
               
            }));

            console.log('✅ Built selectedUnitDetailsFull:', JSON.stringify(builtDetails));

            this.selectedUnitDetailsFull = builtDetails;

            

            this.showDontSplitModal = true;
        })
        .catch(error => {
            console.error('Error fetching unit details for multiple units:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Failed to fetch unit details.',
                    variant: 'error'
                })
            );
        })
        .finally(() => {
            this.isCartLoading = false;
        });


    }
    else
    {
    const promises = this.selectedUnitIds.map(assetId =>
        
        getUnitDetails({ assetId })
            .then(res => ({
                taf: Number(res.taf) || 0,
                rent: Number(res.rent) || 0
            }))
            .catch(err => {
                console.error('Error fetching unit details for', assetId, err);
                return { taf: 0, rent: 0 }; // fallback
            })
    );

    Promise.all(promises)
        .then(results => {
            const builtDetails = results.map((res, index) => ({
                Id: this.selectedUnitIds[index],
                Name: this.selectedUnitDetails?.[index]?.Name || '',
                taf: Number(res.taf) || 0,
                sd: 0, 
                rent: Number(res.rent) || 0,
                adminFees: Number(res.adminFees) || 0

            }));

            console.log('Built selectedUnitDetailsFull:', JSON.stringify(builtDetails));

            this.selectedUnitDetailsFull = builtDetails;

            this.sharedTaf = Number(results[0]?.taf) || 0;
            this.sharedSd = 0; 
            this.sharedAdminFees = 0; 

            this.showDontSplitModal = true;
        })
        .catch(error => {
            console.error('Error fetching unit details for multiple units:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Failed to fetch unit details.',
                    variant: 'error'
                })
            );
        })
        .finally(() => {
            this.isCartLoading = false;
        });
    }
}



handleCancelDontSplit() {
    this.showDontSplitModal = false;
}



handleSharedSdChange(event) {
  const value = Number(event.target.value) || 0;
  this.sharedSd = value;
  this.selectedUnitDetailsFull = this.selectedUnitDetailsFull.map(u => ({
    ...u,
    sd: value
  }));
}
handleSharedAFChange(event) {
  const value = Number(event.target.value) || 0;
  this.sharedAdminFees = value;
  this.selectedUnitDetailsFull = this.selectedUnitDetailsFull.map(u => ({
    ...u,
    adminFees: value
  }));
}

handleSharedTafChange(event) {
  const value = Number(event.target.value) || 0;
  this.sharedTaf = value;
  this.selectedUnitDetailsFull = this.selectedUnitDetailsFull.map(u => ({
    ...u,
    taf: value
  }));
}
handleDeveloperFromPicker(e) {
    const pickedId = (e?.detail?.recordId || '').trim();
    const pickedName = e?.detail?.value || '';

    if (this.hasDeveloper && this.opportunityDeveloper) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Developer Already Assigned',
                message: 'This opportunity already has a developer and it cannot be changed.',
                variant: 'warning'
            })
        );

        this.newDeveloperId = this.opportunityDeveloper;
        this.newDeveloperName = pickedName;
        return;
    }

    this.newDeveloperId = pickedId;
    this.newDeveloperName = pickedName;
}


handleAddCompanyClick() {
    this.showCreateCompanyModal = true;
}

handleCloseCreateCompanyModal() {
    this.showCreateCompanyModal = false;
    this.companyName = '';
    this.companyTradeLicense ='';
}

handleCompanyNameChange(event) {
    this.companyName = event.target.value;
}
handleTradeLicenseChange(event) {
    this.companyTradeLicense = event.target.value;
}

handleCreateCompanyConfirm() {
    console.log('ߔ堃ompany creation started');
    if (!this.companyName || this.companyName.trim() === '') {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Missing Required Field',
                message: 'Company Name is required.',
                variant: 'error'
            })
        );
        return;
    }
    if (!this.companyTradeLicense || this.companyTradeLicense.trim() === '') {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Missing Required Field',
                message: 'Company Trade License is required.',
                variant: 'error'
            })
        );
        return;
    }

    this.isCartLoading = true;
    console.log('ߔ堩sCartLoading set to TRUE');

    createCompanyAccount({
        companyName: this.companyName.trim(),
        companyTradeLicense : this.companyTradeLicense.trim()
    })
    .then(result => {
        console.log('✅ Company account result:', result);
        if (result.error) {
            throw new Error(result.message);
        }

        this.newDeveloperId = result.accountId;
        this.newDeveloperName = result.accountName;

        if (result.isDuplicate) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Duplicate Found',
                    message: result.message + ' This company has been selected.',
                    variant: 'warning'
                })
            );
        } else {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: result.message,
                    variant: 'success'
                })
            );
        }

        this.showCreateCompanyModal = false;
        this.companyName = '';
        this.companyTradeLicense ='';
    })
    .catch(error => {
        console.error('Error creating company:', error);
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: error.message || 'Failed to create company account.',
                variant: 'error'
            })
        );
    })
    .finally(() => {
        console.log('ߔ堆inally block - setting isCartLoading to FALSE');
        this.isCartLoading = false;
    });
}

proceedCreateNewAssetOffPlan() {
    createAssetAndAddtoOppOffPlan({
        opportunityId: this.recordId,
        unitPrice: Number(this.newUnitPrice),
        unitType: this.selectedNewUnitType,
        developerId: this.newDeveloperId,
        remarks: this.newRemarks,
        unitNumber: this.newUnitNumber,
        admBuildingNumber: this.newADMBuildingNumber,
        admPlotNumber: this.newADMPlotNumber,
        admUnitNumber: this.newADMUnitNumber,
        admSectorName: this.newADMSectorName,
        dldBuildingNumber: this.newDLDBuildingNumber,
        dldPlotNumber: this.newDLDPlotNumber,
        dldUnitNumber: this.newDLDUnitNumber,
        dldSectorName: this.newDLDSectorName
    })
    .then(() => {
        this.showCreateNewModal = false;
    })
    .then(() => this.fetchUnits())
    .then(() => {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Success',
            message: 'Asset and Opportunity Product created successfully.',
            variant: 'success'
        }));
    })
    .catch(error => {
        console.error('Error in create asset:', error);
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: error?.body?.message || 'Failed to create asset.',
            variant: 'error'
        }));
    })
    .finally(() => {
        this.isCartLoading = false;
    });
}


handleConfirmDontSplit() {
    try {
        this.selectedUnitIds = (this.selectedUnitDetailsFull || []).map(u => u.Id);

        const cleanUnitIds = JSON.parse(JSON.stringify(this.selectedUnitIds || []));

        console.log('Final cleanUnitIds before Apex:', cleanUnitIds, Array.isArray(cleanUnitIds));

        if (!cleanUnitIds.length) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'No Units Selected',
                    message: 'Please select at least one unit before confirming.',
                    variant: 'error'
                })
            );
            return;
        }
        if(this.secondaryMarket)
        {
        
            const unitMap = {};

            this.selectedUnitDetailsFull.forEach(detail => {
                unitMap[detail.Id] = {
                    unitId: detail.Id,
                    unitPrice: detail.UnitPrice,
                    /*commission: detail.Commission,
                    commission2: detail.Commission2,
                    commissionSource: detail.CommissionSource*/
                };
            });
            console.log(this.selectedUnitDetailsFull);
            const invalidDetails = this.selectedUnitDetailsFull.filter( d=>
                    !d.UnitPrice 
            );
            console.log('Inv',invalidDetails);
            console.log('comm',this.commission);
            console.log('comm2',this.commission2);
            console.log('source',this.selectedComissionSource);
            if (invalidDetails.length > 0 || !this.selectedComissionSource || !this.commission|| (this.selectedComissionSource==='Both' && (!this.commission|| !this.commission2))) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Missing Required Fields',
                        message: 'Please fill Required Fields',
                        variant: 'error'
                    })
                );
                return; 
            }
            
            addBulkUnitsToOppProducts({
            unitList:unitMap,
            opportunityId: this.recordId,
            commission: Number(this.commission),
            commission2 : this.commission2? Number(this.commission2):null,
            commissionSource: this.selectedComissionSource
        
            })
            .then((data) => {
                
                this.showDontSplitModal = false;

            })
            .then(() => this.updateNotifyCustomerFlagAfterAction())
            .then(() => this.fetchUnits())
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Opportunity Product created.',
                        variant: 'success'
                    })
                );
            })
            .catch((error) => {
                console.error('Error in handleDetailsConfirm:', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message:
                            error?.body?.message ||
                            'Failed to complete unit update or quote process.',
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                this.isCartLoading = false;
            });
        }
        else{
        // ߔ頖alidate SD values for all selected units
        const invalidUnits = (this.selectedUnitDetailsFull || []).filter(
            u => !u.sd || isNaN(u.sd) || u.sd <= 0
        );
        if (invalidUnits.length > 0) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Missing SD Value',
                    message: 'Please enter valid SD values for all units before confirming.',
                    variant: 'error'
                })
            );
            return;
        }



        const rentValue = Number(this.selectedUnitDetailsFull[0]?.rent) || 0;
const tafValue  = Number(this.selectedUnitDetailsFull[0]?.taf)  || 0;
const sdValue   = Number(this.selectedUnitDetailsFull[0]?.sd)   || 0;
const adminFeesValue   = Number(this.selectedUnitDetailsFull[0]?.adminFees)   || 0;



        console.log('Sending to Apex:', {
            unitIds: cleanUnitIds,
            opportunityId: this.recordId,
            rent: rentValue,
            sd: sdValue,
            taf: tafValue,
            adminFees:adminFeesValue
        });

        this.isCartLoading = true;

        addUnitsToQuote_DontSplit({
            unitIds: cleanUnitIds,
            opportunityId: this.recordId,
            rent: rentValue,
            sd: sdValue,
            taf: tafValue,
            adminFees: adminFeesValue
        })
            .then(() => {
                this.showDontSplitModal = false;

                return updateAssetStatus({ unitIds: cleanUnitIds });
            })
            .then(() => this.updateNotifyCustomerFlagAfterAction())
            .then(() => this.fetchUnits())
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: `Quote Line Items created for ${cleanUnitIds.length} units and marked Under Offer.`,
                        variant: 'success'
                    })
                );
            })
            .catch(error => {
                console.error('Error in handleConfirmDontSplit:', error);
                console.error('Apex Error Details:', JSON.stringify(error?.body, null, 2));

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error?.body?.message || 'Failed to process selected units.',
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                this.isCartLoading = false;
            });
    }
    } catch (jsError) {
        console.error('JS Exception in handleConfirmDontSplit:', jsError);
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: 'Unexpected client-side error occurred.',
                variant: 'error'
            })
        );
        this.isCartLoading = false;
    }
}
handleCreateNew()
{
    this.showCreateNewModal = true;
}
handleCreateNewCloseModal()
{
    this.showCreateNewModal = false;
}
handleDuplicateCloseModal()
{
    this.showDuplicateAssetModal = false;
}
handleNewUnitNumberChange(event)
{
this.newUnitNumber = event.target.value;
}
handleNewRemarksChange(event)
{
this.newRemarks = event.target.value;
}
handleNewUnitTypeChange(event) {
        this.selectedNewUnitType = event.detail.value;
        console.log('Selected:', this.selectedNewUnitType);
}
handleNewCommissionChange(event) {
    this.newCommission = parseFloat(event.target.value);
}
handleNewCommission2Change(event) {
    this.newCommission2 = parseFloat(event.target.value);
}
handleNewCommissionSourceChange(event) {
        this.selectedNewComissionSource = event.detail.value;
        if(this.selectedNewComissionSource ==='Both')
        {
            this.showCommission2New = true;
            this.newCommissionLabel ='Seller Commission %';
        }
        else{
            this.showCommission2New = false;
            this.newCommissionLabel='Commission %';
        }

        console.log('Selected:', this.selectedNewComissionSource);
}
handleNewPriceChange(event) {
    this.newUnitPrice = parseFloat(event.target.value);
}


handleAddAccountClick() {
    this.showCreateAccountModal = true;
}

handleCloseCreateAccountModal() {
    this.showCreateAccountModal = false;
    this.clearAccountFields();
}

clearAccountFields() {
    this.accFirstName = '';
    this.accLastName = '';
    this.accEmiratesId = '';
    this.accPassportNumber = '';
    this.accEmail = '';
    this.accMobileCountryCode = '';
    this.accMobilePhone = '';
}

handleAccFieldChange(event) {
    const field = event.target.dataset.field;
    const value = event.detail?.value !== undefined ? event.detail.value : event.target.value;
    
    switch(field) {
        case 'firstName': this.accFirstName = value; break;
        case 'lastName': this.accLastName = value; break;
        case 'emiratesId': this.accEmiratesId = value; break;
        case 'passportNumber': this.accPassportNumber = value; break;
        case 'email': this.accEmail = value; break;
        case 'mobileCountryCode': this.accMobileCountryCode = value; break;
        case 'mobilePhone': this.accMobilePhone = value; break;
    }
}

handleCreateAccountConfirm() {
    console.log('ߔ堁ccount creation started');
    if (!this.accFirstName || !this.accLastName) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Missing Required Fields',
                message: 'First Name and Last Name are required.',
                variant: 'error'
            })
        );
        return;
    }

    if (!this.accEmiratesId && !this.accPassportNumber) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Missing Identification',
                message: 'Either Emirates ID or Passport Number is required.',
                variant: 'error'
            })
        );
        return;
    }

    this.isCartLoading = true;
    console.log('ߔ堩sCartLoading set to TRUE');

    createAccount({
        firstName: this.accFirstName,
        lastName: this.accLastName,
        emiratesId: this.accEmiratesId,
        passportNumberPc: this.accPassportNumber,
        email: this.accEmail,
        mobileCountryCode: this.accMobileCountryCode,
        mobilePhone: this.accMobilePhone
    })
    .then(result => {
        console.log('✅ Account created:', result);
        if (result.error) {
            throw new Error(result.message);
        }

        this.newOwnedById = result.accountId;
        this.newOwnedByName = result.accountName;

        if (result.isDuplicate) {
            this.duplicateMessage = `Matching account found: ${result.accountName}`;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Duplicate Found',
                    message: result.message + ' This account has been selected.',
                    variant: 'warning'
                })
            );
        } else {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: result.message,
                    variant: 'success'
                })
            );
        }

        this.showCreateAccountModal = false;
        this.clearAccountFields();
    })
    .catch(error => {
        console.error('Error creating account:', error);
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: error.message || 'Failed to create account.',
                variant: 'error'
            })
        );
    })
    .finally(() => {
        console.log('ߔ堆inally block - setting isCartLoading to FALSE');
        this.isCartLoading = false;
    });
}

handleOwnedByFromPicker(e) {
  this.newOwnedById = (e?.detail?.recordId || '').trim();
  console.log('OwnedBy from record-picker:', this.newOwnedById);
}
handleADMFieldChange(event) {
    const field = event.target.dataset.field;
    const value = event.target.value;
    switch(field) {
        case 'building': this.newADMBuildingNumber = value; break;
        case 'plot': this.newADMPlotNumber = value; break;
        case 'unit': this.newADMUnitNumber = value; break;
        case 'sector': this.newADMSectorName = value; break;
        case 'dld-building': this.newDLDBuildingNumber = value; break;
        case 'dld-plot': this.newDLDPlotNumber = value; break;
        case 'dld-unit': this.newDLDUnitNumber = value; break;
        case 'dld-sector': this.newDLDSectorName = value; break;
    }
}


handleCreateNewConfirm() {
    if (!this.recordId) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Missing Opportunity',
            message: 'Could not find the Opportunity Id (recordId).',
            variant: 'error'
        }));
        return;
    }

    if (this.isOffPlan) {
        // Off-Plan validation
        if (
            !this.newDeveloperId ||
            !this.selectedNewUnitType ||
            !this.newUnitNumber ||
            !this.newUnitPrice
        ) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Missing Required Fields',
                message: 'Please fill all required fields before creating the asset.',
                variant: 'error'
            }));
            return;
        }
    } else {
        // Secondary Market validation
        if (
            !this.newOwnedById ||
            !this.selectedNewUnitType ||
            !this.newUnitNumber ||
            !this.newUnitPrice ||
            !this.newCommission ||
            !this.selectedNewComissionSource || 
            (this.selectedNewComissionSource === 'Both' && (!this.newCommission || !this.newCommission2))
        ) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Missing Required Fields',
                message: 'Please fill all required fields before creating the asset.',
                variant: 'error'
            }));
            return;
        }
    }


    this.isCartLoading = true;

    const building = this.newADMBuildingNumber.trim();
    const plot = this.newADMPlotNumber.trim();
    const unit = this.newADMUnitNumber.trim();
    const sector = this.newADMSectorName.trim();

    const isDubai = this.interestedLocation === 'Dubai';
    const duplicateCheckPromise = isDubai
        ? checkDuplicateDLDAsset({
              buildingNumber: this.newDLDBuildingNumber.trim(),
              plotNumber: this.newDLDPlotNumber.trim(),
              unitNumber: this.newDLDUnitNumber.trim(),
              sectorName: this.newDLDSectorName.trim()
          })
        : checkDuplicateADMAsset({
              buildingNumber: building,
              plotNumber: plot,
              unitNumber: unit,
              sectorName: sector
          });

    duplicateCheckPromise
        .then(dup => {
            if (dup) {
                this.duplicateAssetId = dup.assetId;
                this.duplicateAssetName = dup.assetName;
                this.showDuplicateAssetModal = true;
                this.isCartLoading = false;
            } else {
                if (this.isOffPlan) {
                    this.proceedCreateNewAssetOffPlan();
                } else {
                    this.proceedCreateNewAsset();
                }
            }
        })
        .catch(error => {
            console.error('Duplicate check error:', error);
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Failed to verify existing assets.',
                variant: 'error'
            }));
            this.isCartLoading = false;
        });
}

proceedCreateNewAsset() {
    createAssetAndAddtoOpp({
        opportunityId: this.recordId,
        commission: Number(this.newCommission),
        commission2: this.newCommission2? Number(this.newCommission2):null,
        commissionSource: this.selectedNewComissionSource,
        unitPrice: Number(this.newUnitPrice),
        unitType: this.selectedNewUnitType,
        ownedById: this.newOwnedById,
        remarks: this.newRemarks,
        unitNumber: this.newUnitNumber,
        admBuildingNumber: this.newADMBuildingNumber,
        admPlotNumber: this.newADMPlotNumber,
        admUnitNumber: this.newADMUnitNumber,
        admSectorName: this.newADMSectorName,
        dldBuildingNumber: this.newDLDBuildingNumber,
        dldPlotNumber: this.newDLDPlotNumber,
        dldUnitNumber: this.newDLDUnitNumber,
        dldSectorName: this.newDLDSectorName
    })
    .then(() => {
        this.showCreateNewModal = false;
    })
    /*.then(() => this.updateNotifyCustomerFlagAfterAction())*/
    .then(() => this.fetchUnits())
    .then(() => {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Success',
            message: 'Asset and Opportunity Product created successfully.',
            variant: 'success'
        }));
    })
    .catch(error => {
        console.error('Error in create asset:', error);
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: error?.body?.message || 'Failed to create asset.',
            variant: 'error'
        }));
    })
    .finally(() => {
        this.isCartLoading = false;
    });
}

handleConfirmDuplicateAsset() {
    this.isCartLoading = true;
    addUnitToOpportunityProducts({
        unitIds: [this.duplicateAssetId],
        opportunityId: this.recordId,
        commission: Number(this.newCommission),
        commissionSource: this.selectedNewComissionSource,
        unitPrice: Number(this.newUnitPrice),
        ownedById: this.newOwnedById 
    })
    .then(() => this.updateNotifyCustomerFlagAfterAction())
    .then(() => this.fetchUnits())
    .then(() => {
        this.showDuplicateAssetModal = false;
        this.showCreateNewModal = false;
        this.dispatchEvent(new ShowToastEvent({
            title: 'Linked Existing Asset',
            message: 'Existing asset linked to opportunity successfully.',
            variant: 'success'
        }));
    })
    .catch(error => {
        console.error('Error linking existing asset:', error);
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: error?.body?.message || 'Failed to link existing asset.',
            variant: 'error'
        }));
    })
    .finally(() => {
        this.isCartLoading = false;
    });
}
handleOwnedByFromPicker(e) {
  const pickedId = (e?.detail?.recordId || '').trim();
  this.newOwnedById = pickedId;

  if (this.hasSeller && pickedId && pickedId !== this.sellerId) {
    this.dispatchEvent(
      new ShowToastEvent({
        title: 'Seller Conflict',
        message:
          'There can only be one Seller on this Opportunity. The Owned By field was reset to the Seller account.',
        variant: 'warning'
      })
    );
    this.newOwnedById = this.sellerId;
    this.newOwnedByName = this.sellerName;
  }
}

developerFilter = {
    criteria: [
        {
            fieldPath: 'RecordTypeName__c',
            operator: 'eq',
            value: 'ECSS_Company'
        }
    ]
};



    
}