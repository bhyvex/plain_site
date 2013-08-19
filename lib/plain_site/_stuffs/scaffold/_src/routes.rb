#coding:utf-8



$site.route(
	url_pattern: 'index.html',
	data: {site: $site},
	template: 'index.html',
    build_anyway:true
)

$site.route(
    url_pattern: 'about.html',
    data: $site.db / :about ,
    template: 'post.html'
)


$site.route(
    url_pattern: '{data_id}.html',
    data: 'essays/*',
    template: 'post.html'
)

$site.route(
    url_pattern: 'programming/{slug}.html',
    data: 'programming/*',
    template: 'post.html'
)


$site.db.subs.each do |cat|
    $site.route(
        url_pattern: "#{cat.name}/{slug}.html",
        data: cat.posts/5 ,
        template: 'list.html'
    )
end

