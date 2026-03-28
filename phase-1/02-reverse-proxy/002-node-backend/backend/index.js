import Fastify from "fastify";

const fastify = Fastify({
	logger: true,
});

fastify.get("/", function (request, reply) {
	reply.send({ hello: "world" });
});

try {
	await fastify.listen({ port: 3000, host: "0.0.0.0" });
} catch (err) {
	fastify.log.error(err);
	process.exit(1);
}
