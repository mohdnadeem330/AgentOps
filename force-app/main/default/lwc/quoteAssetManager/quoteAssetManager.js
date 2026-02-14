import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getProjects from '@salesforce/apex/QuoteAssetManagerController.getProjects';
import getBuildings from '@salesforce/apex/QuoteAssetManagerController.getBuildings';
import getAssets from '@salesforce/apex/QuoteAssetManagerController.getAssets';
import getQuoteLineItems from '@salesforce/apex/QuoteAssetManagerController.getQuoteLineItems';
import createQuoteLineItems from '@salesforce/apex/QuoteAssetManagerController.createQuoteLineitems';
import deleteQuoteLineItems from '@salesforce/apex/QuoteAssetManagerController.deleteQuoteLineItems';

export default class QuoteAssetManager extends LightningElement {
    @api recordId; // Quote Id
    @track projectOptions = [];
    @track buildingOptions = [];
    @track statusOptions = [];
    @track assets = [];
    @track filteredAssets = [];
    @track quoteLineItems = [];
    @track filteredQuoteLineItems = [];
    @track selectedProject;
    @track selectedBuilding;
    @track selectedStatus;
    @track selectedAssets = [];
    @track selectedQuoteLineItems = [];
    @track noAssetsMessage;
    @track noQuoteLineItemsMessage;
    @track assetSearchTerm = '';
    @track quoteLineItemSearchTerm = '';

    wiredQuoteLineItemsResult;
    wiredAssetsResult;

    assetColumns = [
        { label: 'Name', fieldName: 'Name', type: 'text' },
        { label: 'Product', fieldName: 'Product2Name', type: 'text' },
        { label: 'Asset Category', fieldName: 'Asset_Category__c', type: 'text' },
        { label: 'Area', fieldName: 'Area__c', type: 'text' },
        { label: 'Status', fieldName: 'Status', type: 'text' }
    ];

    quoteLineItemColumns = [
        { label: 'Asset', fieldName: 'assetName', type: 'text' },
        { label: 'Product', fieldName: 'productName', type: 'text' },
        { label: 'Quantity', fieldName: 'Quantity', type: 'number' },
        { label: 'Unit Price', fieldName: 'UnitPrice', type: 'currency' },
        { label: 'Total Price', fieldName: 'TotalPrice', type: 'currency' },
        { label: 'Asset Status', fieldName: 'assetStatus', type: 'text' }
    ];

    connectedCallback() {
        this.loadProjects();
    }

    async loadProjects() {
        try {
            const projects = await getProjects();
            this.projectOptions = projects.map(project => ({
                label: project.Name,
                value: project.Id
            }));
            if (this.projectOptions.length > 0) {
                this.selectedProject = this.projectOptions[0].value;
                await this.loadBuildings();
            }
        } catch (error) {
            this.showToast('Error', 'Error loading projects', 'error');
        }
    }

    @wire(getQuoteLineItems, { quoteId: '$recordId' })
    wiredQuoteLineItems(result) {
        this.wiredQuoteLineItemsResult = result;
        const { data, error } = result;
        if (data) {
            this.quoteLineItems = data.map(item => ({
                Id: item.Id,
                Quantity: item.Quantity,
                UnitPrice: item.UnitPrice,
                TotalPrice: item.TotalPrice,
                productName: item.Product2 ? item.Product2.Name : '',
                assetName: item.Asset__r ? item.Asset__r.Name : '',
                assetStatus: item.Asset__r ? item.Asset__r.Status : ''
            }));
            this.filteredQuoteLineItems = this.quoteLineItems;
            this.noQuoteLineItemsMessage = this.quoteLineItems.length ? '' : 'No quote line items found.';
            this.statusOptions = [
                { label: 'None', value: '' },
                ...[...new Set(this.quoteLineItems.map(item => item.assetStatus))].map(status => ({
                label: status,
                value: status
                })).filter(option => option.label !== null)
            ];
        } else if (error) {
            this.showToast('Error', 'Error loading quote line items', 'error');
        }
    }

    @wire(getAssets, { buildingId: '$selectedBuilding', quoteId: '$recordId' })
    wiredAssets(result) {
        this.wiredAssetsResult = result;
        const { data, error } = result;
        if (data) {
            this.assets = data.map(asset => ({
                Id: asset.Id,
                Name: asset.Name,
                Product2Name: asset.Product2 ? asset.Product2.Name : null,
                Asset_Category__c: asset.Asset_Category__c,
                Area__c: asset.Area__c,
                Status: asset.Status                
            }));
            this.filteredAssets = this.assets.map(asset => ({
                ...asset,
                Product2Name: asset.Product2Name ? asset.Product2Name : 'N/A' // Ensure Product2Name is always displayed
            }));
            this.noAssetsMessage = this.assets.length ? '' : 'No available assets found for this building.';
        } else if (error) {
            this.showToast('Error', 'Error loading assets', 'error');
        }
    }

    handleProjectChange(event) {
        this.selectedProject = event.detail.value;
        this.loadBuildings();
    }

    handleBuildingChange(event) {
        this.selectedBuilding = event.detail.value;
        this.refreshBothLists();
    }

    handleStatusChange(event) {
        this.selectedStatus = event.detail.value;
        this.filterQuoteLineItems();
    }

    handleAssetSelection(event) {
        this.selectedAssets = event.detail.selectedRows;
    }

    handleQuoteLineItemSelection(event) {
        this.selectedQuoteLineItems = event.detail.selectedRows;
    }

    handleAssetSearch(event) {
        this.assetSearchTerm = event.target.value.toLowerCase();
        this.filterAssets(this.assetSearchTerm);
    }

    handleQuoteLineItemSearch(event) {
        this.quoteLineItemSearchTerm = event.target.value.toLowerCase();
        this.filterQuoteLineItems(this.quoteLineItemSearchTerm);
    }

    filterAssets(assetSearch) {
        this.filteredAssets = this.assets.filter(asset =>
            asset.Name.toLowerCase().includes(assetSearch) ||
            (asset.Product2Name && asset.Product2Name.toLowerCase().includes(assetSearch)) ||
            asset.Asset_Category__c.toLowerCase().includes(assetSearch) ||
            asset.Area__c.toLowerCase().includes(assetSearch) ||
            asset.Status.toLowerCase().includes(assetSearch)
        );

        this.noAssetsMessage = this.filteredAssets.length ? '' : 'No available assets found for this building.';
        this.selectedAssets = this.selectedAssets.filter(selectedAsset =>
            this.filteredAssets.some(filteredAsset => filteredAsset.Id === selectedAsset.Id)
        );
    }  

    filterQuoteLineItems(quoteLineItemSearch) {
        let filtered = this.quoteLineItems;
        if (this.selectedStatus) {
            if (this.selectedStatus === '') {
                filtered = this.quoteLineItems;
            } else {
                filtered = filtered.filter(item => item.assetStatus === this.selectedStatus);
            }
        }
        if (quoteLineItemSearch) {
            filtered = filtered.filter(item =>
                item.assetName.toLowerCase().includes(quoteLineItemSearch) ||
                item.productName.toLowerCase().includes(quoteLineItemSearch) ||
                item.Quantity.toString().includes(quoteLineItemSearch) ||
                item.UnitPrice.toString().includes(quoteLineItemSearch) ||
                item.TotalPrice.toString().includes(quoteLineItemSearch) ||
                item.assetStatus.toLowerCase().includes(quoteLineItemSearch)
            );
        }

        this.filteredQuoteLineItems = filtered;
        this.noQuoteLineItemsMessage = this.filteredQuoteLineItems.length ? '' : 'No quote line items found for the selected criteria.';

        this.selectedQuoteLineItems = this.selectedQuoteLineItems.filter(selectedQuoteLineItem =>
            this.filteredQuoteLineItems.some(filteredQuoteLineItem => filteredQuoteLineItem.Id === selectedQuoteLineItem.Id)
        );
    }

    async loadBuildings() {
        try {
            const buildings = await getBuildings({ projectId: this.selectedProject });
            this.buildingOptions = buildings.map(building => ({
                label: building.Name,
                value: building.Id
            }));
            if (this.buildingOptions.length > 0) {
                this.selectedBuilding = this.buildingOptions[0].value;
                this.refreshBothLists();
            } else {
                this.selectedBuilding = null;
                this.assets = [];
                this.filteredAssets = [];
            }
        } catch (error) {
            this.showToast('Error', 'Error loading buildings', 'error');
        }
    }

    async handleAddAssets() {
        if (this.selectedAssets.length === 0) {
            this.showToast('Error', 'Please select at least one asset', 'error');
            return;
        }

        try {
            await createQuoteLineItems({
                quoteId: this.recordId,
                assetIds: this.selectedAssets.map(asset => asset.Id)
            });
            this.showToast('Success', 'Quote line items created successfully', 'success');
            await this.refreshBothLists();
            this.selectedAssets = [];
            this.template.querySelector('lightning-datatable[data-id="assetTable"]').selectedRows = [];
        } catch (error) {
            this.showToast('Error', 'Error creating quote line items: ' + error.body.message, 'error');
        }
    }

    async handleRemoveQuoteLineItems() {
        if (this.selectedQuoteLineItems.length === 0) {
            this.showToast('Error', 'Please select at least one quote line item', 'error');
            return;
        }

        try {
            await deleteQuoteLineItems({
                quoteLineItemIds: this.selectedQuoteLineItems.map(item => item.Id).join(',')
            });
            this.showToast('Success', 'Quote line items removed successfully', 'success');
            await this.refreshBothLists();
            this.selectedQuoteLineItems = [];
            this.template.querySelector('lightning-datatable[data-id="quoteLineItemTable"]').selectedRows = [];
        } catch (error) {
            this.showToast('Error', 'Error removing quote line items: ' + error.body.message, 'error');
        }
    }

    async refreshBothLists() {
        try {
            await Promise.all([
                this.refreshQuoteLineItems(),
                this.refreshAssets()
            ]);
        } catch (error) {
            this.showToast('Error', 'Error refreshing lists', 'error');
        }
    }

    async refreshQuoteLineItems() {
        try {
            await refreshApex(this.wiredQuoteLineItemsResult);
            this.filterQuoteLineItems();
        } catch (error) {
            this.showToast('Error', 'Error refreshing quote line items', 'error');
        }
    }

    async refreshAssets() {
        try {
            await refreshApex(this.wiredAssetsResult);
            this.filterAssets(this.assetSearchTerm);
        } catch (error) {
            this.showToast('Error', 'Error refreshing assets', 'error');
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
            }),
        );
    }
}