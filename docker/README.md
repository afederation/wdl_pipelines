Source for Docker contains which are used the MacCoss lab pipelines, in this repository. 

# PanoramaClient
Docker source for managing files on a [Panorama Server](https://panoramaweb.org/wiki/home/page.view?name=default) such as [PanoramaWeb](https://panoramaweb.org/wiki/home/page.view?name=default).

This container is used by most of the pipelines used in this repository.


# panorama-files
Docker contains managing files on a [Panorama Server](https://panoramaweb.org/wiki/home/page.view?name=default) such as [PanoramaWeb](https://panoramaweb.org/wiki/home/page.view?name=default). This container uses Python scripts to perform the management. 

This container is used only by pipelines in the `cromwell/archive` folder. **Do not use this container in pipelines**. This is no longer supported for use with MacCoss.lab pipelines.