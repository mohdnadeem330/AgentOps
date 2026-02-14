import { LightningElement, track, wire } from 'lwc';
import getUnits from '@salesforce/apex/ECSS_UnitDeleteController.getFilteredUnits';
import getAllProjects from '@salesforce/apex/ECSS_UnitDeleteController.getAllProjects';
import getAllZones from '@salesforce/apex/ECSS_UnitDeleteController.getAllZones';
import getAllBuildings from '@salesforce/apex/ECSS_UnitDeleteController.getAllBuildings';
import getAllUnitTypes from '@salesforce/apex/ECSS_UnitDeleteController.getAllUnitTypes';
import getAllUnitAreas from '@salesforce/apex/ECSS_UnitDeleteController.getAllUnitAreas';
import getAllViews from '@salesforce/apex/ECSS_UnitDeleteController.getAllViews';
import getAllUnitUsages from '@salesforce/apex/ECSS_UnitDeleteController.getAllUnitUsages';
import markUnitsForDeletion from '@salesforce/apex/ECSS_UnitDeleteController.markUnitsForDeletion';
import { CurrentPageReference } from 'lightning/navigation';


import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class EcssUnitDelete extends LightningElement {
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

    @track projectOptions = [];
    @track zoneOptions = [];
    @track buildingOptions = [];
    @track unitTypeOptions = [];
    @track unitAreaOptions = [];
    @track viewOptions = [];
    @track unitUsageOptions = [];

    @track allUnits = [];
    @track selectedRowIds = [];
    @track isLoading = false;

    @track recordId;

     @wire(CurrentPageReference)
    getPageReferenceParameters(currentPageReference) {
       if (currentPageReference) {
          console.log(currentPageReference);
          this.recordId = currentPageReference.attributes.recordId;
        
       }
    }

    connectedCallback() {
        this.fetchAllFilterOptions();
        this.fetchUnits();
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
        this.isLoading = true;
            const bathsInt = this.selectedBaths ? parseInt(this.selectedBaths, 10) : null;

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
    opportunityId: this.recordId 
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

            }));
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
            case 'Unit Usage': this.selectedUnitUsage = value; break;

        }
    }
    handleSearchClick() {
        this.fetchUnits();
    }

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedRowIds = selectedRows.map(row => row.Id);
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


    get selectedCount() {
    return this.selectedRowIds.length;
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


    handleDeleteUnits() {
        if (!Array.isArray(this.selectedRowIds) || this.selectedRowIds.length === 0) {
            this.showToast('Error', 'Please select at least one unit to delete.', 'error');
            return;
        }

        this.isLoading = true;

       markUnitsForDeletion({ 
    unitIds: this.selectedRowIds,
    opportunityId: this.recordId   // <-- pass current opp id
})

            .then(() => {
                this.showToast('Success', 'Units marked for deletion. Manager notified.', 'success');
                this.selectedRowIds = [];
                this.fetchUnits();
            })
            .catch(error => {
                console.error(error);
                this.showToast('Error', 'Something went wrong while deleting units.', 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
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
    get hasUnits() {
        return this.filteredUnits.length > 0;
    }

    get noResultsFound() {
        return !this.isLoading && this.filteredUnits.length === 0;
    }
}