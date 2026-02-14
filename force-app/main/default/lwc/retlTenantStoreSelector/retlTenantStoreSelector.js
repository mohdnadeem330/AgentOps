import { LightningElement, api, track, wire } from 'lwc';
import Images from "@salesforce/resourceUrl/RETLTenantPortalImages";
import getStores from '@salesforce/apex/RETL_ServiceRequestWizardController.getStores';
import searchProperties from '@salesforce/apex/RETL_ServiceRequestWizardController.getAllProperties';
import getUnitsByProperty from '@salesforce/apex/RETL_ServiceRequestWizardController.searchRetailUnits';
import getOrderItemFromContractorSelection from '@salesforce/apex/RETL_ServiceRequestWizardController.getOrderItemFromContractorSelection';
export default class RetlTenantStoreSelector extends LightningElement {
    houseimage = Images + '/Request/house.png';
    @api contactId;
    @api profileName;
    @track stores = [];
    @track error;
    isTenant = true;

    searchTerm = '';
    @track searchResults = [];
    selectedProperty = null;
    @track units = [];
    workInCommonArea = false;
    showUnits = false;
    isRendered = false;

    // UI state
    @track isSearching = false;
    debounceTimer;

    connectedCallback() {
        this.isRendered = false;
    }

    renderedCallback() {
        //if (!this.isRendered) {
        console.log('Updated profileName: ', this.profileName);
        if (this.profileName === 'Retail Contractor Profile' || this.profileName === 'DM Requestor Partner Login') {
            this.isTenant = false;
        }
        else if (this.profileName === 'Retail Tenant Partner Login') {
            this.isTenant = true;
        }
        console.log('profileName:', this.profileName);
        console.log('this.isTenatt:', this.isTenant);
        this.isRendered = true;
        //}
    }
    @wire(getStores, { contactId: '$contactId' })
    wiredGetStores({ error, data }) {
        if (data) {
            console.log('this.contactId', this.contactId);
            console.log('Stores:', JSON.stringify(data));
            this.stores = data;
            this.error = undefined;
        } else if (error) {
            console.error('Error fetching stores', JSON.stringify(error));
            this.error = error;
            this.stores = [];
        }
    }

    handleClick(event) {
        const orderItemId = event.currentTarget.dataset.id;
        // Find the store object
        const store = this.stores.find(s => s.orderItemId === orderItemId);
        if (store) {
            console.log('handleClick - store:', JSON.stringify(store));
            this.dispatchEvent(
                new CustomEvent('storeselected', {
                    detail: { storeName: store.unit, orderId: store.leaseId }, // or whatever field you want
                    bubbles: true,
                    composed: true
                })
            );
        } else {
            console.warn('Store not found for:', orderItemId);
        }
    }

    handleSearchChange(event) {
        const value = event.target.value;
        this.searchTerm = value;


        // debounce
        window.clearTimeout(this.debounceTimer);
        if (!value || value.length < 2) {
            this.searchResults = [];
            return;
        }
        this.debounceTimer = window.setTimeout(() => {
            this.doSearch(value);
        }, 300);
    }

    async doSearch(keyword) {
        this.isSearching = true;
        try {
            const results = await searchProperties({ keyword });
            console.log('search results:', JSON.stringify(results));
            this.searchResults = results || [];
        } catch (err) {
            // handle error (toast in real app)
            console.error('search error', err);
            this.searchResults = [];
        } finally {
            this.isSearching = false;
        }
    }

    async selectProperty(event) {
        const id = event.currentTarget.dataset.id;
        this.selectedProperty = this.searchResults.find(p => p.Id === id) || null;
        this.searchResults = [];
        this.searchTerm = this.selectedProperty ? this.selectedProperty.Property_Name__c : '';


        if (this.selectedProperty) {
            this.showUnits = true;
            await this.loadUnits(this.selectedProperty.Property_Code__c);
        } else {
            this.showUnits = false;
            this.units = [];
        }
    }

    async loadUnits(propertyCode) {
        try {
            const unitList = await getUnitsByProperty({ propertyCode });
            // add selected flag to each
            this.units = (unitList || []).map(u => ({ ...u, selected: false, cssClass: 'unit-item' }));
            console.log('unitList:', JSON.stringify(unitList));
        } catch (err) {
            console.error('units error', err);
            this.units = [];
        }
    }
    handleCommonAreaChange(event) {
        this.workInCommonArea = event.target.checked;
        if (this.workInCommonArea) {
            // clear selected units
            this.units = this.units.map(u => ({ ...u, selected: false }));
        }
    }

    unitSearchTerm = '';
    get filteredUnits() {
        if (!this.unitSearchTerm) {
            return this.units;
        }
        let keyword = this.unitSearchTerm.toLowerCase();
        return this.units.filter(
            u => (u.Unit_Code__c || '').toLowerCase().includes(keyword)
        );
    }

    handleUnitSearch(event) {
        this.unitSearchTerm = event.target.value;
    }

    handleUnitSelect(event) {
        const selectedId = event.currentTarget.dataset.id;

        this.units = this.units.map(u => {
            if (u.Id === selectedId) {
                return {
                    ...u,
                    selected: true,
                    cssClass: 'unit-item unit-selected'
                };
            }
            return {
                ...u,
                selected: false,
                cssClass: 'unit-item'
            };
        });

        console.log('units after select:', JSON.stringify(this.units));
        this.handleNext();
    }


    handleCancel() {
        // reset form
        this.searchTerm = '';
        this.searchResults = [];
        this.selectedProperty = null;
        this.units = [];
        this.workInCommonArea = false;
        this.showUnits = false;
    }


    async handleNext() {
        // collect payload and fire event so parent can continue the wizard or navigate
        // let selectedUnit = this.workInCommonArea ? null : this.units.find(u => u.selected);
        // console.log('selectedUnit:', JSON.stringify(selectedUnit));
        // let storeName = this.workInCommonArea ? 'Common Area' : selectedUnit.Unit_Code__c ? selectedUnit.Unit_Code__c : this.manualUnitSelection ? this.manualUnitSelection : '';
        // let propCode = selectedUnit.Property_Code__c;
        let selectedUnit = this.workInCommonArea ? null : this.units.find(u => u.selected);

        console.log('selectedUnit:', selectedUnit ? JSON.stringify(selectedUnit) : 'NONE SELECTED');

        // Define fallback values
        let storeName = this.workInCommonArea
            ? 'Common Area'
            : selectedUnit
                ? selectedUnit.Unit_Code__c
                : this.manualUnitSelection || '';

        let propCode = selectedUnit ? selectedUnit.Property_Code__c : null;
        const orderId = await getOrderItemFromContractorSelection({ propertyCode:propCode });
        console.log('orderId', orderId);
        this.dispatchEvent(
            new CustomEvent('storeselected', {
                detail: { storeName: storeName, orderId: orderId }, // or whatever field you want
                bubbles: true,
                composed: true
            })
        );
    }
    manualUnitSelection;
    handleChange(event) {
        this.manualUnitSelection = event.target.value;
    }
}