function prune_map(lon1, lat1, lon2, lat2)
	current_dir = pwd()
	run(`podman run -v $(current_dir):/data/ --privileged osm:latest osmconvert /data/Raleigh_nearby.osm -b=$(lon1),$(lat1),$(lon2),$(lat2) -o=/data/minimap.osm`)
	return nothing
end
