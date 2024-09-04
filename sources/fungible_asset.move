module aptos_asset::fungible_asset {
    use aptos_framework::fungible_asset::{Self, MintRef, TransferRef, BurnRef, Metadata, FungibleAsset};
    use aptos_framework::object::{Self, Object};
    use aptos_framework::primary_fungible_store;
    use std::error;
    use std::signer;
    use std::string::utf8;
    use std::option;

    // Only fungible asset metadata owner can make changes.
    const ENOT_OWNER: u64 = 1;
    const ASSET_SYMBOL: vector<u8> = b"META";

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct ManagedFungibleAsset has key {
        mint_ref: MintRef,
        transfer_ref: TransferRef,
        burn_ref: BurnRef,
    }

    // Initialize metadata object and store the refs.
    fun init_module(admin: &signer) {
        let constructor_ref = &object::create_named_object(admin, ASSET_SYMBOL);
        primary_fungible_store::create_primary_store_enabled_fungible_asset (
            constructor_ref,
            option::none(),
            utf8(b"META Coin"), /* name */
            utf8(ASSET_SYMBOL), /* symbol */
            8, /* decimals */
            utf8(b"https://drive.google.com/file/d/1vFm-kF6O3onxPgFJ_rVLh9YGFT_fFWM6/view?usp=sharing"), /* icon */
            utf8(b"http://metaschool.so"), /* project */
        );

        // Create mint/burn/transfer refs to allow creator to manage the fungible asset.
        let mint_ref = fungible_asset::generate_mint_ref(constructor_ref);
        let burn_ref = fungible_asset::generate_burn_ref(constructor_ref);
        let transfer_ref = fungible_asset::generate_transfer_ref(constructor_ref);
        let metadata_object_signer = object::generate_signer(constructor_ref);
        move_to(
            &metadata_object_signer,
            ManagedFungibleAsset { mint_ref, transfer_ref, burn_ref }
        );// initialize
    }
    /// Return the address of the managed fungible asset that's created when this module is deployed.
    public fun get_metadata(): Object<Metadata> {
        let asset_address = object::create_object_address(&@aptos_asset, ASSET_SYMBOL);
        object::address_to_object<Metadata>(asset_address)
    }
    public entry fun mint(admin: &signer, to: address, amount: u64) acquires ManagedFungibleAsset {
        let asset = get_metadata();
        let to_wallet = primary_fungible_store::ensure_primary_store_exists(to,asset);
        let fa = fungible_asset::mint(&ManagedFungibleAsset.mint_ref, amount);
        fungible_asset::deposit_with_ref(&ManagedFungibleAsset.transfer_ref,to_wallet,fa);
    }
    public entry fun transfer(admin: &signer, from: address, to: address, amount: u64) acquires ManagedFungibleAsset {
        let asset = get_metadata();
        let from_wallet = primary_fungible_store::primary_store(from, asset);
        let to_wallet = primary_fungible_store::ensure_primary_store_exists(to, asset);
        fungible_asset::transfer_with_ref(&ManagedFungibleAsset.transfer_ref, from, to, amount);
    }
    public entry fun burn(admin: &signer, from: address, amount: u64) acquires ManagedFungibleAsset{
        let asset = get_metadata();
        let from_wallet = primary_fungible_store::primary_store(from, asset);
        fungible_asset::burn_from(ManagedFungibleAsset.burn_ref, from, amount);
    }
}

