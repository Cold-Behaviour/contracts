const Layers = artifacts.require("Layers");

contract("Layers", async accounts => {
    it("test upload of traits", async () => {
        const instance = await Layers.deployed();
        await instance.uploadLayers(0,[{ cid: "QmbnKmfvA2csCDdYTGC4ThVwkvn1WbFRd1SXgkc2wxMdpX", name: "Background 0"}]);
    });
});