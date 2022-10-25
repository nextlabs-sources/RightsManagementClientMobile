package nxl.types;


public class NXDocument extends NxFileBase {
    {
        super.setIsFolder(false);
    }

    @Override
    public NxFileBase findNode(String path) {
        if (getLocalPath().equalsIgnoreCase(path))
            return this;
        else
            return null;
    }
}
